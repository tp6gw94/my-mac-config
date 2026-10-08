#!/bin/sh
set -eu

root=$(CDPATH="" cd "$(dirname "$0")/.." && pwd -P)
script="$root/bin/cowtree"

if [ "$(uname -s)" != Darwin ]; then
  printf '略過：cowtree 測試需要 macOS 的 cp -cR\n'
  exit 0
fi

fail() {
  printf '失敗：%s\n' "$*" >&2
  exit 1
}

assert_eq() {
  expected=$1
  actual=$2
  label=$3
  [ "$expected" = "$actual" ] || fail "${label}（預期：${expected}；實際：${actual}）"
}

assert_file_contains() {
  file=$1
  text=$2
  label=$3
  if ! grep -F -- "$text" "$file" >/dev/null 2>&1; then
    fail "$label"
  fi
}

assert_file_bytes() {
  printf '%s\n' "$2" | cmp - "$1" >/dev/null 2>&1 || fail "$3"
}

expect_failure() {
  label=$1
  shift
  if "$@" >"$tmp/failure.stdout" 2>"$tmp/failure.stderr"; then
    fail "$label 應該失敗"
  fi
  if [ -s "$tmp/failure.stdout" ]; then
    fail "$label 不應輸出 stdout"
  fi
}

expect_failure_in_directory() {
  label=$1
  directory=$2
  shift 2
  if (cd "$directory" && "$@") >"$tmp/failure.stdout" 2>"$tmp/failure.stderr"; then
    fail "$label 應該失敗"
  fi
  if [ -s "$tmp/failure.stdout" ]; then
    fail "$label 不應輸出 stdout"
  fi
}

tmp=$(mktemp -d "${TMPDIR:-/tmp}/cowtree-test.XXXXXX")
tmp=$(cd "$tmp" && pwd -P)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

repo="$tmp/project"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.email cowtree-test@example.com
git -C "$repo" config user.name cowtree-test
printf '*.ignored\nnode_modules/\n' >"$repo/.gitignore"
printf 'committed\n' >"$repo/tracked.txt"
mkdir -p "$repo/node_modules/root-package" "$repo/packages/app/node_modules/nested-package"
printf 'root module\n' >"$repo/node_modules/root-package/index.js"
printf 'nested module\n' >"$repo/packages/app/node_modules/nested-package/index.js"
printf 'nested source\n' >"$repo/packages/app/source.txt"
printf 'hidden\n' >"$repo/.hidden"
mkdir -p "$repo/.git/node_modules"
printf 'git metadata\n' >"$repo/.git/node_modules/marker"
symlink_target="$tmp/symlink-target"
mkdir "$symlink_target"
printf 'outside\n' >"$symlink_target/file"
ln -s "$symlink_target" "$repo/external-link"
git -C "$repo" add .gitignore tracked.txt
git -C "$repo" -c core.hooksPath=/dev/null commit -qm 初始提交
printf 'dirty\n' >>"$repo/tracked.txt"
printf 'ignored\n' >"$repo/only.ignored"

# 若錯誤地執行複本內的 hook，這個檔案會被建立。
hook_marker="$tmp/hook-ran"
printf '#!/bin/sh\ntouch %s\n' "$hook_marker" >"$repo/.git/hooks/post-checkout"
chmod +x "$repo/.git/hooks/post-checkout"
source_status=$(git -C "$repo" status --porcelain)
source_head=$(git -C "$repo" rev-parse HEAD)
source_branch=$(git -C "$repo" branch --show-current)

default_destination="$tmp/project-feature-foo"
stdout_file="$tmp/default.stdout"
stderr_file="$tmp/default.stderr"
if ! (cd "$repo" && "$script" feature/foo) >"$stdout_file" 2>"$stderr_file"; then
  fail "預設目的地複製失敗：$(cat "$stderr_file")"
fi
assert_eq "$default_destination" "$(cat "$stdout_file")" 'stdout 應只有目的地'
[ -d "$default_destination" ] || fail '複本目錄不存在'
assert_eq feature/foo "$(git -C "$default_destination" symbolic-ref --short HEAD)" '複本目前分支錯誤'
git -C "$default_destination" show-ref --verify --quiet refs/heads/feature/foo || fail '複本沒有新分支'
assert_file_contains "$default_destination/tracked.txt" dirty '未保留未提交內容'
[ -f "$default_destination/only.ignored" ] || fail '未保留被忽略檔案'
[ ! -e "$default_destination/node_modules" ] || fail '根目錄 node_modules 不應複製'
[ ! -e "$default_destination/packages/app/node_modules" ] || fail '巢狀 node_modules 不應複製'
assert_file_contains "$default_destination/packages/app/source.txt" 'nested source' '其他巢狀檔案未保留'
assert_file_contains "$default_destination/.hidden" hidden '隱藏檔案未保留'
assert_file_contains "$default_destination/.git/node_modules/marker" 'git metadata' '.git 中繼資料不應被過濾'
[ -L "$default_destination/external-link" ] || fail '符號連結未保留'
assert_eq "$symlink_target" "$(readlink "$default_destination/external-link")" '符號連結不應被追蹤'
assert_file_contains "$repo/node_modules/root-package/index.js" 'root module' '來源根目錄 node_modules 被改變'
assert_file_contains "$repo/packages/app/node_modules/nested-package/index.js" 'nested module' '來源巢狀 node_modules 被改變'
[ -f "$default_destination/.git" ] && fail '複本的 .git 不應是檔案'
[ ! -e "$hook_marker" ] || fail '建立分支時不應執行複本 hook'
assert_eq "$source_status" "$(git -C "$repo" status --porcelain)" '來源工作樹狀態被改變'
assert_eq "$source_head" "$(git -C "$repo" rev-parse HEAD)" '來源 HEAD 被改變'
assert_eq "$source_branch" "$(git -C "$repo" branch --show-current)" '來源目前分支被改變'
if git -C "$repo" show-ref --verify --quiet refs/heads/feature/foo; then
  fail '新分支不應出現在來源'
fi

activation_repo="$tmp/activation-source"
mkdir "$activation_repo"
git -C "$activation_repo" init -q -b main
git -C "$activation_repo" config user.email cowtree-test@example.com
git -C "$activation_repo" config user.name cowtree-test
printf '*.ignored\n' >"$activation_repo/.gitignore"
printf 'base modified\n' >"$activation_repo/modified"
printf 'base removed\n' >"$activation_repo/removed"
printf 'base staged\n' >"$activation_repo/staged"
printf 'base dirty\n' >"$activation_repo/dirty"
git -C "$activation_repo" add .
git -C "$activation_repo" -c core.hooksPath=/dev/null commit -qm base
git -C "$activation_repo" -c core.hooksPath=/dev/null checkout -qb target
printf 'target modified\n' >"$activation_repo/modified"
rm "$activation_repo/removed"
printf 'target added\n' >"$activation_repo/added"
printf 'target ignored\n' >"$activation_repo/collision.ignored"
git -C "$activation_repo" add -A
git -C "$activation_repo" add -f collision.ignored
git -C "$activation_repo" -c core.hooksPath=/dev/null commit -qm target
activation_target=$(git -C "$activation_repo" rev-parse HEAD)
git -C "$activation_repo" -c core.hooksPath=/dev/null checkout -q main
printf 'local staged\n' >"$activation_repo/staged"
git -C "$activation_repo" add staged
printf 'local dirty\n' >"$activation_repo/dirty"
printf 'local untracked\n' >"$activation_repo/untracked"
printf 'local ignored\n' >"$activation_repo/local.ignored"
printf '#!/bin/sh\ntouch %s\nexit 1\n' "$hook_marker" >"$activation_repo/.git/hooks/post-checkout"
chmod +x "$activation_repo/.git/hooks/post-checkout"
activation_status=$(git -C "$activation_repo" status --porcelain)
activation_head=$(git -C "$activation_repo" rev-parse HEAD)
activation_refs=$(git -C "$activation_repo" show-ref)
activation_index=$(git -C "$activation_repo" ls-files --stage)
cp "$activation_repo/.git/index" "$tmp/activation.index"
activation_copy="$tmp/activation-copy"
(cd "$activation_repo" && "$script" target "$activation_copy") >"$tmp/activation.stdout" 2>"$tmp/activation.stderr" || fail 'Existing branch activation failed'
assert_eq "$activation_copy" "$(cat "$tmp/activation.stdout")" 'Activation stdout'
assert_eq target "$(git -C "$activation_copy" branch --show-current)" 'Exact existing branch'
assert_eq "$activation_target" "$(git -C "$activation_copy" rev-parse HEAD)" 'Existing branch commit'
assert_file_bytes "$activation_copy/modified" 'target modified' 'Tracked modified bytes'
assert_file_bytes "$activation_copy/added" 'target added' 'Tracked added bytes'
[ ! -e "$activation_copy/removed" ] || fail 'Tracked removed file remains'
assert_eq 'target modified' "$(git -C "$activation_copy" show :modified)" 'Modified index bytes'
assert_eq 'target added' "$(git -C "$activation_copy" show :added)" 'Added index bytes'
if git -C "$activation_copy" ls-files --error-unmatch removed >/dev/null 2>&1; then
  fail 'Removed file remains in index'
fi
assert_eq 'local staged' "$(git -C "$activation_copy" show :staged)" 'Staged index preserved'
assert_file_bytes "$activation_copy/staged" 'local staged' 'Staged worktree preserved'
assert_eq 'base dirty' "$(git -C "$activation_copy" show :dirty)" 'Unstaged index preserved'
assert_file_bytes "$activation_copy/dirty" 'local dirty' 'Unstaged bytes preserved'
assert_file_bytes "$activation_copy/untracked" 'local untracked' 'Untracked bytes preserved'
assert_file_bytes "$activation_copy/local.ignored" 'local ignored' 'Ignored bytes preserved'
assert_eq 'M  staged' "$(git -C "$activation_copy" status --porcelain -- staged)" 'Staged status preserved'
assert_eq ' M dirty' "$(git -C "$activation_copy" status --porcelain -- dirty)" 'Unstaged status preserved'
[ ! -e "$hook_marker" ] || fail 'Existing branch ran checkout hook'
assert_eq "$activation_status" "$(git -C "$activation_repo" status --porcelain)" 'Activation changed source status'
assert_eq "$activation_head" "$(git -C "$activation_repo" rev-parse HEAD)" 'Activation changed source commit'
assert_eq main "$(git -C "$activation_repo" branch --show-current)" 'Activation changed source branch'
assert_eq "$activation_refs" "$(git -C "$activation_repo" show-ref)" 'Activation changed source refs'
cmp "$tmp/activation.index" "$activation_repo/.git/index" || fail 'Activation changed source index'
assert_file_bytes "$activation_repo/modified" 'base modified' 'Activation changed source tracked bytes'
assert_file_bytes "$activation_repo/removed" 'base removed' 'Activation removed source file'
[ ! -e "$activation_repo/added" ] || fail 'Activation added source file'
assert_file_bytes "$activation_repo/staged" 'local staged' 'Activation changed source staged bytes'
assert_file_bytes "$activation_repo/dirty" 'local dirty' 'Activation changed source dirty bytes'
assert_file_bytes "$activation_repo/untracked" 'local untracked' 'Activation changed source untracked bytes'
assert_file_bytes "$activation_repo/local.ignored" 'local ignored' 'Activation changed source ignored bytes'

current_copy="$tmp/current-copy"
(cd "$activation_repo" && "$script" main "$current_copy") >"$tmp/current.stdout" 2>"$tmp/current.stderr" || fail 'Current branch activation failed'
assert_eq "$current_copy" "$(cat "$tmp/current.stdout")" 'Current branch stdout'
assert_eq main "$(git -C "$current_copy" branch --show-current)" 'Current branch name'
assert_eq "$activation_head" "$(git -C "$current_copy" rev-parse HEAD)" 'Current branch commit'
assert_eq "$activation_status" "$(git -C "$current_copy" status --porcelain)" 'Current branch dirty state'
assert_eq "$activation_index" "$(git -C "$current_copy" ls-files --stage)" 'Current branch changed index entries'
expect_failure_in_directory 'Existing branch destination collision' "$activation_repo" "$script" target "$current_copy"
assert_file_bytes "$current_copy/dirty" 'local dirty' 'Collision changed destination'

for conflict in dirty staged untracked ignored; do
  conflict_repo="$tmp/conflict-$conflict"
  cp -R "$activation_repo" "$conflict_repo"
  case "$conflict" in
    dirty|staged) conflict_file=modified ;;
    untracked) conflict_file=added ;;
    ignored) conflict_file=collision.ignored ;;
  esac
  printf 'original conflict bytes\n' >"$conflict_repo/$conflict_file"
  if [ "$conflict" = staged ]; then
    git -C "$conflict_repo" add "$conflict_file"
  fi
  conflict_status=$(git -C "$conflict_repo" status --porcelain)
  conflict_index=$(git -C "$conflict_repo" ls-files --stage)
  conflict_copy="$tmp/conflict-copy-$conflict"
  expect_failure_in_directory "$conflict overwrite conflict" "$conflict_repo" "$script" target "$conflict_copy"
  [ -d "$conflict_copy/.git" ] || fail 'Conflict copy was not retained'
  assert_file_contains "$tmp/failure.stderr" 'error:' 'Git conflict diagnostic missing'
  assert_file_contains "$tmp/failure.stderr" "copy retained at: $conflict_copy" 'Retained copy diagnostic missing'
  for conflict_directory in "$conflict_repo" "$conflict_copy"; do
    assert_file_bytes "$conflict_directory/$conflict_file" 'original conflict bytes' 'Conflict bytes overwritten'
    assert_eq "$conflict_status" "$(git -C "$conflict_directory" status --porcelain)" 'Conflict changed status'
    assert_eq "$activation_head" "$(git -C "$conflict_directory" rev-parse HEAD)" 'Conflict changed commit'
    assert_eq main "$(git -C "$conflict_directory" branch --show-current)" 'Conflict changed branch'
    assert_eq "$conflict_index" "$(git -C "$conflict_directory" ls-files --stage)" 'Conflict changed index entries'
  done
  [ ! -e "$hook_marker" ] || fail 'Conflict ran checkout hook'
done

git -C "$activation_repo" remote add origin "$activation_repo"
git -C "$activation_repo" update-ref refs/remotes/origin/remote-only "$activation_target"
remote_copy="$tmp/remote-only-copy"
(cd "$activation_repo" && "$script" remote-only "$remote_copy") >"$tmp/remote.stdout" 2>"$tmp/remote.stderr" || fail 'Remote-only name failed to create local branch'
assert_eq "$remote_copy" "$(cat "$tmp/remote.stdout")" 'Remote-only stdout'
assert_eq remote-only "$(git -C "$remote_copy" branch --show-current)" 'Remote-only exact local branch'
assert_eq "$activation_head" "$(git -C "$remote_copy" rev-parse HEAD)" 'Remote-only branch guessed remote commit'
assert_eq "$activation_status" "$(git -C "$remote_copy" status --porcelain)" 'New branch changed dirty state'
assert_eq "$activation_index" "$(git -C "$remote_copy" ls-files --stage)" 'New branch changed index entries'
if git -C "$remote_copy" config --get branch.remote-only.remote >/dev/null 2>&1; then
  fail 'Remote-only branch acquired remote tracking'
fi
if git -C "$activation_repo" show-ref --verify --quiet refs/heads/remote-only; then
  fail 'Remote-only branch appeared in source'
fi
expect_failure_in_directory 'Branch shorthand' "$activation_repo" "$script" '@{-1}' "$tmp/shorthand-copy"
[ ! -e "$tmp/shorthand-copy" ] || fail 'Branch shorthand created a destination'
cp "$activation_repo/.git/index" "$tmp/pre-index-env.index"
expect_failure_in_directory 'GIT_INDEX_FILE environment' "$activation_repo" env GIT_INDEX_FILE="$activation_repo/.git/index" "$script" target "$tmp/external-index-copy"
[ ! -e "$tmp/external-index-copy" ] || fail 'GIT_INDEX_FILE created a destination'
assert_file_contains "$tmp/failure.stderr" 'GIT_INDEX_FILE' 'GIT_INDEX_FILE diagnostic missing'
cmp "$tmp/pre-index-env.index" "$activation_repo/.git/index" || fail 'GIT_INDEX_FILE changed source index'

core_worktree_destination="$tmp/core-worktree-copy"
git -C "$repo" config core.worktree "$repo"
expect_failure_in_directory 'core.worktree 設定' "$repo" "$script" feature/core-worktree "$core_worktree_destination"
[ ! -e "$core_worktree_destination" ] || fail 'core.worktree 拒絕後仍建立了目錄'
git -C "$repo" config --unset core.worktree || fail '清除 core.worktree 測試設定失敗'

printf '.git\n' >"$repo/.git/commondir"
commondir_destination="$tmp/commondir-copy"
expect_failure_in_directory '.git/commondir 設定' "$repo" "$script" feature/commondir "$commondir_destination"
[ ! -e "$commondir_destination" ] || fail '.git/commondir 拒絕後仍建立了目錄'
rm -f "$repo/.git/commondir"

collision="$tmp/already-exists"
mkdir -p "$collision"
printf 'keep\n' >"$collision/sentinel"
expect_failure_in_directory '已存在目的地' "$repo" "$script" feature/collision "$collision"
assert_file_contains "$collision/sentinel" keep '碰撞目的地遭覆寫'

inside="$repo/inside-copy"
expect_failure_in_directory '來源內目的地' "$repo" "$script" feature/inside "$inside"
[ ! -e "$inside" ] || fail '來源內拒絕後仍建立了目錄'

ln -s "$repo" "$tmp/repo-alias"
symlink_inside="$tmp/repo-alias/inside-copy"
expect_failure_in_directory '經由 symlink 的來源內目的地' "$repo" "$script" feature/symlink "$symlink_inside"
[ ! -e "$symlink_inside" ] || fail 'symlink 來源內拒絕後仍建立了目錄'

invalid_destination="$tmp/invalid-branch"
expect_failure_in_directory '無效分支名稱' "$repo" "$script" 'bad..branch' "$invalid_destination"
[ ! -e "$invalid_destination" ] || fail '無效分支拒絕後仍建立了目錄'

if grep -F 'function cowtree()' "$root/zsh/.zshrc" >/dev/null 2>&1; then
  fail 'zsh 不應定義 cowtree wrapper'
fi

linked="$tmp/linked-worktree"
if ! git -C "$repo" -c core.hooksPath=/dev/null worktree add -q -b linked/test "$linked" HEAD; then
  fail '建立 linked worktree 測試資料失敗'
fi
expect_failure_in_directory 'linked worktree' "$linked" "$script" linked/copy "$tmp/linked-copy"
git -C "$repo" worktree remove -f "$linked" >/dev/null 2>&1 || fail '清理 linked worktree 測試資料失敗'

herdr_stub_dir="$tmp/herdr-stub"
mkdir -p "$herdr_stub_dir"
cat >"$herdr_stub_dir/herdr" <<'HERDR_STUB'
#!/bin/sh
set -eu

log=${COWTREE_HERDR_LOG:?}
index=0
cwd=
previous=
for argument in "$@"; do
  index=$((index + 1))
  printf 'arg%s=%s\n' "$index" "$argument" >>"$log"
  if [ "$previous" = --cwd ]; then
    cwd=$argument
  fi
  previous=$argument
done
printf 'argc=%s\n' "$index" >>"$log"
printf 'branch_at_call=%s\n' "$(git -C "$cwd" branch --show-current 2>/dev/null || printf 'none')" >>"$log"
[ -z "${COWTREE_HERDR_STDOUT:-}" ] || printf '%s\n' "$COWTREE_HERDR_STDOUT"
[ -z "${COWTREE_HERDR_STDERR:-}" ] || printf '%s\n' "$COWTREE_HERDR_STDERR" >&2
if [ "${COWTREE_HERDR_FAIL:-0}" = 1 ]; then
  exit 7
fi
exit 0
HERDR_STUB
chmod +x "$herdr_stub_dir/herdr"

stub_stdout=
stub_stderr=

run_herdr() {
  directory=$1
  log=$2
  shift 2
  (cd "$directory" && env \
    PATH="$herdr_stub_dir:$PATH" \
    HERDR_ENV=1 \
    COWTREE_HERDR_LOG="$log" \
    COWTREE_HERDR_STDOUT="${stub_stdout:-}" \
    COWTREE_HERDR_STDERR="${stub_stderr:-}" \
    COWTREE_HERDR_FAIL=0 \
    "$script" "$@") >"$tmp/herdr.stdout" 2>"$tmp/herdr.stderr"
}

write_herdr_expected_log() {
  expected_file=$1
  destination=$2
  label=$3
  branch_name=$4
  printf 'arg1=workspace\narg2=create\narg3=--cwd\narg4=%s\narg5=--label\narg6=%s\narg7=--focus\nargc=7\nbranch_at_call=%s\n' \
    "$destination" "$label" "$branch_name" >"$expected_file"
}

expect_exit() {
  label=$1
  expected_status=$2
  directory=$3
  shift 3
  status=0
  (cd "$directory" && "$@") >"$tmp/failure.stdout" 2>"$tmp/failure.stderr" || status=$?
  [ "$status" -eq "$expected_status" ] || fail "$label should exit $expected_status（actual $status）"
  [ ! -s "$tmp/failure.stdout" ] || fail "$label should not write stdout"
}

default_herdr_branch=feature/herdr-default
default_herdr_destination="$tmp/project-feature-herdr-default"
default_herdr_log="$tmp/herdr-default.log"
stub_stdout='herdr-output-noise'
stub_stderr='herdr-stderr-marker'
if ! run_herdr "$repo" "$default_herdr_log" "$default_herdr_branch" --herdr; then
  fail "Default Herdr run failed：$(cat "$tmp/herdr.stderr")"
fi
stub_stdout=
stub_stderr=
assert_file_bytes "$tmp/herdr.stdout" "$default_herdr_destination" 'Default Herdr stdout'
assert_file_contains "$tmp/herdr.stderr" 'herdr-stderr-marker' 'Herdr stderr was not preserved'
assert_eq "$default_herdr_branch" "$(git -C "$default_herdr_destination" branch --show-current)" 'Default Herdr branch'
write_herdr_expected_log "$tmp/herdr-expected.log" "$default_herdr_destination" 'project-feature-herdr-default' "$default_herdr_branch"
cmp "$tmp/herdr-expected.log" "$default_herdr_log" || fail 'Default Herdr invocation contract changed'

special_herdr_branch=feature/herdr-special
special_herdr_destination="$tmp/herdr copy \$quoted*"
special_herdr_log="$tmp/herdr-special.log"
if ! run_herdr "$repo" "$special_herdr_log" "$special_herdr_branch" "$special_herdr_destination" --herdr; then
  fail "Special destination Herdr run failed：$(cat "$tmp/herdr.stderr")"
fi
assert_file_bytes "$tmp/herdr.stdout" "$special_herdr_destination" 'Special destination Herdr stdout'
assert_eq "$special_herdr_branch" "$(git -C "$special_herdr_destination" branch --show-current)" 'Special destination Herdr branch'
write_herdr_expected_log "$tmp/herdr-expected.log" "$special_herdr_destination" "herdr copy \$quoted*" "$special_herdr_branch"
cmp "$tmp/herdr-expected.log" "$special_herdr_log" || fail 'Special destination Herdr invocation contract changed'

literal_herdr_branch=feature/herdr-literal
literal_herdr_destination="$tmp/herdr literal"
literal_herdr_log="$tmp/herdr-literal.log"
if ! run_herdr "$repo" "$literal_herdr_log" "$literal_herdr_branch" --herdr -- "$literal_herdr_destination"; then
  fail "Literal destination Herdr run failed：$(cat "$tmp/herdr.stderr")"
fi
assert_file_bytes "$tmp/herdr.stdout" "$literal_herdr_destination" 'Literal destination Herdr stdout'
assert_eq "$literal_herdr_branch" "$(git -C "$literal_herdr_destination" branch --show-current)" 'Literal destination Herdr branch'
write_herdr_expected_log "$tmp/herdr-expected.log" "$literal_herdr_destination" 'herdr literal' "$literal_herdr_branch"
cmp "$tmp/herdr-expected.log" "$literal_herdr_log" || fail 'Literal destination Herdr invocation contract changed'

existing_herdr_destination="$tmp/herdr-existing"
existing_herdr_log="$tmp/herdr-existing.log"
if ! run_herdr "$activation_repo" "$existing_herdr_log" target "$existing_herdr_destination" --herdr; then
  fail "Existing branch Herdr run failed：$(cat "$tmp/herdr.stderr")"
fi
assert_file_bytes "$tmp/herdr.stdout" "$existing_herdr_destination" 'Existing branch Herdr stdout'
assert_eq target "$(git -C "$existing_herdr_destination" branch --show-current)" 'Existing branch Herdr branch'
write_herdr_expected_log "$tmp/herdr-expected.log" "$existing_herdr_destination" 'herdr-existing' target
cmp "$tmp/herdr-expected.log" "$existing_herdr_log" || fail 'Existing branch Herdr invocation contract changed'

unflagged_herdr_log="$tmp/herdr-unflagged.log"
if ! run_herdr "$repo" "$unflagged_herdr_log" feature/herdr-unflagged "$tmp/herdr-unflagged"; then
  fail "Unflagged run failed：$(cat "$tmp/herdr.stderr")"
fi
assert_file_bytes "$tmp/herdr.stdout" "$tmp/herdr-unflagged" 'Unflagged stdout'
[ ! -e "$unflagged_herdr_log" ] || fail 'Unflagged run called herdr'

missing_env_destination="$tmp/herdr-missing-env"
missing_env_log="$tmp/herdr-missing-env.log"
expect_exit 'Unset HERDR_ENV' 1 "$repo" env -u HERDR_ENV PATH="$herdr_stub_dir:$PATH" COWTREE_HERDR_LOG="$missing_env_log" "$script" feature/herdr-missing-env "$missing_env_destination" --herdr
assert_file_contains "$tmp/failure.stderr" 'HERDR_ENV=1 is required' 'Unset HERDR_ENV diagnostic missing'
[ ! -e "$missing_env_destination" ] || fail 'Unset HERDR_ENV created destination'
[ ! -e "$missing_env_log" ] || fail 'Unset HERDR_ENV called herdr'

for bad_env in true 01 ''; do
  bad_env_destination="$tmp/herdr-bad-env-$bad_env"
  bad_env_log="$tmp/herdr-bad-env-$bad_env.log"
  expect_exit "HERDR_ENV=$bad_env" 1 "$repo" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV="$bad_env" COWTREE_HERDR_LOG="$bad_env_log" "$script" feature/herdr-bad-env "$bad_env_destination" --herdr
  assert_file_contains "$tmp/failure.stderr" 'HERDR_ENV=1 is required' 'Invalid HERDR_ENV diagnostic missing'
  [ ! -e "$bad_env_destination" ] || fail 'Invalid HERDR_ENV created destination'
  [ ! -e "$bad_env_log" ] || fail 'Invalid HERDR_ENV called herdr'
done

no_cli_destination="$tmp/herdr-no-cli"
no_cli_log="$tmp/herdr-no-cli.log"
expect_exit 'Missing herdr CLI' 1 "$repo" env PATH=/usr/bin:/bin HERDR_ENV=1 COWTREE_HERDR_LOG="$no_cli_log" "$script" feature/herdr-no-cli "$no_cli_destination" --herdr
assert_file_contains "$tmp/failure.stderr" 'herdr is not available on PATH' 'Missing herdr CLI diagnostic missing'
[ ! -e "$no_cli_destination" ] || fail 'Missing herdr CLI created destination'
[ ! -e "$no_cli_log" ] || fail 'Missing herdr CLI ran herdr'

fail_herdr_branch=feature/herdr-fail
fail_herdr_destination="$tmp/herdr-fail"
fail_herdr_log="$tmp/herdr-fail.log"
expect_exit 'Herdr creation failure' 1 "$repo" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV=1 COWTREE_HERDR_LOG="$fail_herdr_log" COWTREE_HERDR_STDOUT='herdr-failure-noise' COWTREE_HERDR_STDERR='herdr-failure-stderr' COWTREE_HERDR_FAIL=1 "$script" "$fail_herdr_branch" "$fail_herdr_destination" --herdr
assert_file_contains "$tmp/failure.stderr" 'herdr-failure-stderr' 'Herdr failure stderr was not preserved'
assert_file_contains "$tmp/failure.stderr" "copy retained at: $fail_herdr_destination" 'Herdr failure retained copy diagnostic missing'
assert_eq "$fail_herdr_branch" "$(git -C "$fail_herdr_destination" branch --show-current)" 'Herdr failure lost branch'
write_herdr_expected_log "$tmp/herdr-expected.log" "$fail_herdr_destination" 'herdr-fail' "$fail_herdr_branch"
cmp "$tmp/herdr-expected.log" "$fail_herdr_log" || fail 'Herdr failure invocation contract changed'

conflict_herdr_log="$tmp/herdr-conflict.log"
expect_exit 'Herdr checkout conflict' 1 "$tmp/conflict-dirty" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV=1 COWTREE_HERDR_LOG="$conflict_herdr_log" "$script" target "$tmp/herdr-conflict-copy" --herdr
assert_file_contains "$tmp/failure.stderr" "copy retained at: $tmp/herdr-conflict-copy" 'Herdr conflict retained copy diagnostic missing'
[ -d "$tmp/herdr-conflict-copy/.git" ] || fail 'Herdr conflict did not retain copy'
[ ! -e "$conflict_herdr_log" ] || fail 'Herdr checkout conflict called herdr'

collision_herdr_log="$tmp/herdr-collision.log"
expect_exit 'Herdr destination collision' 1 "$repo" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV=1 COWTREE_HERDR_LOG="$collision_herdr_log" "$script" feature/herdr-collision "$collision" --herdr
assert_file_contains "$tmp/failure.stderr" "目的地已存在，拒絕覆寫：$collision" 'Herdr collision diagnostic missing'
[ ! -e "$collision_herdr_log" ] || fail 'Herdr destination collision called herdr'
assert_file_bytes "$collision/sentinel" keep 'Herdr destination collision changed destination'

expect_exit 'Missing branch' 2 "$tmp" "$script"
expect_exit 'Duplicate --herdr' 2 "$tmp" "$script" feature/herdr-duplicate --herdr --herdr
expect_exit 'Excess destination operand' 2 "$tmp" "$script" feature/herdr-excess "$tmp/herdr-excess-one" "$tmp/herdr-excess-two"
expect_exit 'Destination after literal tail' 2 "$tmp" "$script" feature/herdr-literal-excess "$tmp/herdr-literal-excess" -- "$tmp/herdr-literal-excess-extra"
assert_file_contains "$tmp/failure.stderr" '--herdr' 'Usage text should mention --herdr'
[ ! -e "$tmp/herdr-excess-one" ] || fail 'Usage failure created a destination'

empty_herdr_log="$tmp/herdr-empty.log"
expect_exit 'Empty destination with --herdr' 1 "$repo" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV=1 COWTREE_HERDR_LOG="$empty_herdr_log" "$script" feature/herdr-empty '' --herdr
assert_file_contains "$tmp/failure.stderr" '目的地不可為空。' 'Empty destination diagnostic missing'
[ ! -e "$empty_herdr_log" ] || fail 'Empty destination called herdr'

literal_flag_log="$tmp/herdr-literal-flag.log"
expect_exit 'Literal --herdr destination inside source' 1 "$repo" env PATH="$herdr_stub_dir:$PATH" HERDR_ENV=1 COWTREE_HERDR_LOG="$literal_flag_log" "$script" feature/herdr-literal-flag -- --herdr
assert_file_contains "$tmp/failure.stderr" '目的地不可位於來源儲存庫內' 'Literal source-inside rejection missing'
[ ! -e "$literal_flag_log" ] || fail 'Literal --herdr destination called herdr'
[ ! -e "$repo/--herdr" ] || fail 'Literal destination created inside source'

expect_exit 'Dash destination inside source' 1 "$repo" "$script" feature/herdr-dash --unknown-flag
assert_file_contains "$tmp/failure.stderr" '目的地不可位於來源儲存庫內' 'Dash destination literal rejection missing'
[ ! -e "$repo/--unknown-flag" ] || fail 'Dash destination created inside source'

printf 'cowtree 測試通過\n'

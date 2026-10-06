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
  if ! grep -F "$text" "$file" >/dev/null 2>&1; then
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

printf 'cowtree 測試通過\n'

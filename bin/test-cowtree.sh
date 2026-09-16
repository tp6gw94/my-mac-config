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

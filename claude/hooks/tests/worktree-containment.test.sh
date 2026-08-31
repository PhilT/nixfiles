#!/usr/bin/env bash
# Tests for hooks/worktree-containment.sh. Run:
#   bash ~/.claude/hooks/tests/worktree-containment.test.sh
#
# The hook reads the session's git state from the working directory, so the test builds a
# throwaway repo and runs the hook from inside one of its worktrees. The worktrees are put in
# three places on purpose, mirroring zuno: nested in the main checkout, and outside it
# entirely. A hook that infers the repo root and prefix-tests passes the nested cases and
# fails the outside one.
# 0 lets the edit through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/worktree-containment.sh}"
pass=0
fail=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
mkdir -p "$repo" "$tmp/elsewhere"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo hello > "$repo/README.md"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" worktree add -q "$repo/.claude/worktrees/mine" -b mine
git -C "$repo" worktree add -q "$repo/.claude/worktrees/other" -b other
git -C "$repo" worktree add -q "$tmp/elsewhere/far" -b far

mine="$repo/.claude/worktrees/mine"
other="$repo/.claude/worktrees/other"
far="$tmp/elsewhere/far"

check() {
  local name=$1 from=$2 path=$3 want=$4 got
  jq -n --arg p "$path" \
    '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p,content:"x"}}' \
    | (cd "$from" && bash "$HOOK") >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

check 'a file in our own worktree is allowed'          "$mine" "$mine/app.rb"      0
check 'a nested file in our own worktree is allowed'   "$mine" "$mine/a/b/c.rb"    0
check 'a file in the main checkout is refused'         "$mine" "$repo/README.md"   2
check 'a sibling worktree inside the checkout is refused' "$mine" "$other/app.rb"  2
check 'a sibling worktree outside the checkout is refused' "$mine" "$far/app.rb"   2
check 'the far worktree may edit itself'               "$far"  "$far/app.rb"       0
check 'the far worktree may not edit ours'             "$far"  "$mine/app.rb"      2
check 'a path outside the repository is allowed'       "$mine" "/tmp/scratch.rb"   0
check 'a path escaping via .. is resolved first'       "$mine" "$mine/../other/x"  2
check 'a relative path is allowed'                     "$mine" "app/models/x.rb"   0
check 'a main-checkout session is left to project policy' "$repo" "$repo/README.md" 0

# From a subdirectory git answers --git-dir absolute and --git-common-dir relative, so a hook
# comparing them raw reads the main checkout as a worktree and starts refusing there.
mkdir -p "$repo/app" "$mine/app"
check 'a main-checkout subdirectory is still left to project policy' "$repo/app" "$other/app.rb" 0
check 'a worktree subdirectory still refuses a sibling tree'         "$mine/app" "$other/app.rb" 2

jq -n '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:"ls"}}' \
  | (cd "$mine" && bash "$HOOK") >/dev/null 2>&1
if [ $? = 0 ]; then
  pass=$((pass + 1)); printf 'ok    %s\n' 'a payload with no file_path is ignored'
else
  fail=$((fail + 1)); printf 'FAIL  %s\n' 'a payload with no file_path is ignored'
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

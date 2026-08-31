#!/usr/bin/env bash
# Tests for hooks/require-worktree.sh. Run:
#   bash ~/.claude/hooks/tests/require-worktree.test.sh
#
# The hook reads the session's git state from the working directory, so the test builds a
# throwaway repo with a worktree and a gitfile-attached tree, and runs the hook from each.
# 0 lets the edit through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/require-worktree.sh}"
pass=0
fail=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
mkdir -p "$repo" "$tmp/plain"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo hello > "$repo/README.md"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" worktree add -q "$repo/worktrees/mine" -b mine

# A tree attached by gitfile, the /data/work/zuno shape: git from here acts on the checkout.
mkdir -p "$tmp/devbox"
printf 'gitdir: %s/.git\n' "$repo" > "$tmp/devbox/.git"

check() {
  local name=$1 from=$2 want=$3 got
  jq -n --arg p "$from/x.rb" \
    '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p,content:"x"}}' \
    | (cd "$from" && bash "$HOOK") >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

check 'an edit from the main checkout is refused'      "$repo"            2
check 'an edit from a worktree is allowed'             "$repo/worktrees/mine" 0
check 'an edit from a gitfile-attached tree is refused' "$tmp/devbox"      2
check 'a directory outside any repo is ignored'        "$tmp/plain"       0

# From a subdirectory git answers --git-dir absolute and --git-common-dir relative, so a hook
# comparing them raw reads the main checkout as a worktree and allows the edit.
mkdir -p "$repo/app/models" "$repo/worktrees/mine/app"
check 'an edit from a main-checkout subdirectory is refused' "$repo/app"        2
check 'an edit from a deeper subdirectory is refused'        "$repo/app/models" 2
check 'an edit from a worktree subdirectory is allowed'      "$repo/worktrees/mine/app" 0

# A repo that has never made a worktree is not using this model, so it is left alone.
bare="$tmp/solo"
mkdir -p "$bare"
git init -q -b main "$bare"
git -C "$bare" config user.email t@t
git -C "$bare" config user.name t
echo x > "$bare/a.txt"
git -C "$bare" add -A
git -C "$bare" commit -qm init
check 'a repo with no worktrees is left alone'         "$bare"            0

# ...until it grows one, at which point the model is in use.
git -C "$bare" worktree add -q "$bare/wt" -b wt
check 'the same repo is refused once it has a worktree' "$bare"           2

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

#!/usr/bin/env bash
# Tests for hooks/session-type.sh. Run: bash ~/.claude/hooks/tests/session-type.test.sh
#
# The hook reads git state from the working directory and the delivery text from the
# <!-- session-delivery --> range of a CLAUDE.md, so the test builds a throwaway repo laid out
# both ways: the marked CLAUDE.md at the repo root (pacent's shape) and one directory above it
# (zuno's, where the repo is <root>/mono and the marked file sits at <root>).
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/session-type.sh}"
pass=0
fail=0

say() {
  local name=$1 ok=$2
  if [ "$ok" = 0 ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL  %s\n' "$name"
  fi
}

# Run the hook from $1 and echo the additionalContext string.
context() {
  (cd "$1" && CLAUDE_JOB_DIR="${2:-}" bash "$HOOK" 2>/dev/null) \
    | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null
}

has() { case "$2" in *"$1"*) return 0 ;; *) return 1 ;; esac; }

# Write a CLAUDE.md at $1 whose marked range is $2.
marked() {
  printf '%s\n' '# Guide' '' '<!-- session-delivery -->' "$2" '<!-- /session-delivery -->' > "$1"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- pacent shape: marked CLAUDE.md at the repo root ---------------------------------------
repo="$tmp/pacent"
mkdir -p "$repo"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo x > "$repo/a.txt"
git -C "$repo" add -A
git -C "$repo" commit -qm init

out=$(context "$repo")
has 'no worktrees' "$out"; say 'a repo with no worktrees says file work here is allowed' $?
has 'Attended' "$out"; say 'no job dir reports the attended posture' $?

marked "$repo/CLAUDE.md" 'Squash to one commit, then deliver with git push origin HEAD:main.'
git -C "$repo" worktree add -q "$repo/.claude/worktrees/mine" -b mine

out=$(context "$repo")
has 'editing or creating files here is blocked' "$out"; say 'the main checkout is blocked once a worktree exists' $?
has 'git push origin HEAD:main' "$out"; say 'the delivery text is read from the repo root' $?

out=$(context "$repo/.claude/worktrees/mine")
has "Worktree $repo/.claude/worktrees/mine on 'mine'" "$out"; say 'a worktree reports its own path and branch' $?

out=$(context "$repo/.claude/worktrees/mine" "$tmp/job")
has 'Background run' "$out"; say 'a job dir reports the background posture' $?

# A repo that tracks CLAUDE.md carries it into the worktree, and that copy wins: the main
# checkout of a push-only workflow sits behind origin/main and would serve a stale rule.
marked "$repo/.claude/worktrees/mine/CLAUDE.md" 'Deliver by carrier pigeon.'
out=$(context "$repo/.claude/worktrees/mine")
has 'carrier pigeon' "$out"; say "a worktree reads its own marked CLAUDE.md, not the checkout's" $?

# --- zuno shape: repo is <root>/mono, the marked CLAUDE.md sits at <root> -------------------
zroot="$tmp/zuno"
mkdir -p "$zroot/mono"
git init -q -b main "$zroot/mono"
git -C "$zroot/mono" config user.email t@t
git -C "$zroot/mono" config user.name t
printf '%s\n' '# Repo guide' 'No delivery rule here.' > "$zroot/mono/CLAUDE.md"
git -C "$zroot/mono" add -A
git -C "$zroot/mono" commit -qm init
git -C "$zroot/mono" worktree add -q "$zroot/worktrees/TICKET-1" -b TICKET-1
marked "$zroot/CLAUDE.md" 'Delivery when asked is git push -u origin <branch>, then a draft PR based on main.'

out=$(context "$zroot/worktrees/TICKET-1")
has "on 'TICKET-1'" "$out"; say 'a worktree outside the checkout reports its branch' $?
has 'draft PR based on main' "$out"; say 'the delivery text is found one directory above the repo' $?
if has 'push origin HEAD:main' "$out"; then say 'zuno does not get the other repo delivery text' 1; else say 'zuno does not get the other repo delivery text' 0; fi

# --- output shape --------------------------------------------------------------------------
(cd "$repo" && bash "$HOOK" 2>/dev/null) | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null 2>&1
say 'the output is valid UserPromptSubmit JSON' $?

(cd "$tmp" && bash "$HOOK" >/dev/null 2>&1)
say 'a directory outside any repo exits quietly' $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

#!/usr/bin/env bash
# Tests for hooks/worktree-remove.sh. Run: bash ~/.claude/hooks/tests/worktree-remove.test.sh
#
# The event cannot block, so there is no interesting exit code: every case asserts what is left
# on disk afterwards. The hook exists for the branch that default removal leaves behind, and
# these tests are mostly about the cases where it must refuse to tidy up, because the work
# exists nowhere else. The fixture has a real bare remote so "pushed" and "unpushed" differ.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/worktree-remove.sh}"
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

run() {
  jq -n --arg w "$1" --arg c "$2" \
    '{session_id:"t",hook_event_name:"WorktreeRemove",worktree_path:$w,cwd:$c}' \
    | bash "$HOOK" >/dev/null 2>&1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git init -q --bare "$tmp/origin.git"

repo="$tmp/repo"
mkdir -p "$repo"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
git -C "$repo" remote add origin "$tmp/origin.git"
echo x > "$repo/a.txt"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" push -q -u origin main

branch_gone() { ! git -C "$repo" rev-parse --verify --quiet "refs/heads/$1" >/dev/null 2>&1; }
branch_kept() { git -C "$repo" rev-parse --verify --quiet "refs/heads/$1" >/dev/null 2>&1; }

# --- nothing of its own: directory and branch both go ----------------------------------------
git -C "$repo" worktree add -q "$tmp/trees/clean" -b clean
run "$tmp/trees/clean" "$repo"
[ ! -d "$tmp/trees/clean" ]; say 'a worktree with no commits of its own is removed' $?
branch_gone clean; say 'its branch is deleted' $?

# --- committed but on no remote: the case the docs sample destroys ----------------------------
git -C "$repo" worktree add -q "$tmp/trees/unpushed" -b unpushed
echo work > "$tmp/trees/unpushed/b.txt"
git -C "$tmp/trees/unpushed" add -A
git -C "$tmp/trees/unpushed" commit -qm work
run "$tmp/trees/unpushed" "$repo"
[ -d "$tmp/trees/unpushed" ]; say 'a worktree whose commits are on no remote is left in place' $?
branch_kept unpushed; say 'its unpushed branch is kept' $?

# --- the same commits, once pushed ------------------------------------------------------------
git -C "$tmp/trees/unpushed" push -q -u origin unpushed
run "$tmp/trees/unpushed" "$repo"
[ ! -d "$tmp/trees/unpushed" ]; say 'once pushed, the same worktree is removed' $?
branch_gone unpushed; say 'and its branch is deleted' $?

# --- uncommitted changes: nothing is touched ---------------------------------------------------
git -C "$repo" worktree add -q "$tmp/trees/dirty" -b dirty
echo scratch > "$tmp/trees/dirty/c.txt"
run "$tmp/trees/dirty" "$repo"
[ -d "$tmp/trees/dirty" ]; say 'a worktree with uncommitted changes is left in place' $?
[ -f "$tmp/trees/dirty/c.txt" ]; say 'its uncommitted file survives' $?
branch_kept dirty; say 'its branch is kept while the worktree stands' $?

# --- an untracked file counts as work too ------------------------------------------------------
git -C "$repo" worktree add -q "$tmp/trees/untracked" -b untracked
echo scratch > "$tmp/trees/untracked/note.txt"
run "$tmp/trees/untracked" "$repo"
[ -d "$tmp/trees/untracked" ]; say 'an untracked file is enough to keep the worktree' $?

# --- the branch name differs from the last path segment ----------------------------------------
# pacent's shape until now: directory `<name>`, branch `worktree-<name>`. Deriving the branch
# from the segment misses, so the unpushed check never runs and the branch is orphaned.
git -C "$repo" worktree add -q "$tmp/trees/prefixed" -b worktree-prefixed
echo work > "$tmp/trees/prefixed/e.txt"
git -C "$tmp/trees/prefixed" add -A
git -C "$tmp/trees/prefixed" commit -qm work
run "$tmp/trees/prefixed" "$repo"
[ -d "$tmp/trees/prefixed" ]; say 'a prefixed branch with unpushed commits keeps its worktree' $?
branch_kept worktree-prefixed; say 'and keeps the branch' $?

git -C "$tmp/trees/prefixed" push -q -u origin worktree-prefixed
run "$tmp/trees/prefixed" "$repo"
[ ! -d "$tmp/trees/prefixed" ]; say 'once pushed, the prefixed worktree is removed' $?
branch_gone worktree-prefixed; say 'and its prefixed branch is deleted, not orphaned' $?

# --- a slash-named worktree --------------------------------------------------------------------
git -C "$repo" worktree add -q "$tmp/trees/feat/probe" -b feat/probe
echo work > "$tmp/trees/feat/probe/f.txt"
git -C "$tmp/trees/feat/probe" add -A
git -C "$tmp/trees/feat/probe" commit -qm work
run "$tmp/trees/feat/probe" "$repo"
[ -d "$tmp/trees/feat/probe" ]; say 'a slash-named worktree with unpushed commits is left alone' $?
branch_kept feat/probe; say 'and its branch is kept' $?

git -C "$tmp/trees/feat/probe" push -q -u origin feat/probe
run "$tmp/trees/feat/probe" "$repo"
branch_gone feat/probe; say 'once pushed, the slash-named branch is deleted' $?

# --- directory already removed by Claude Code --------------------------------------------------
git -C "$repo" worktree add -q "$tmp/trees/already" -b already
git -C "$repo" worktree remove "$tmp/trees/already"
run "$tmp/trees/already" "$repo"
branch_gone already; say 'a spent branch is deleted even when the directory is already gone' $?

git -C "$repo" worktree add -q "$tmp/trees/gone-unpushed" -b gone-unpushed
echo work > "$tmp/trees/gone-unpushed/d.txt"
git -C "$tmp/trees/gone-unpushed" add -A
git -C "$tmp/trees/gone-unpushed" commit -qm work
git -C "$repo" worktree remove --force "$tmp/trees/gone-unpushed"
run "$tmp/trees/gone-unpushed" "$repo"
branch_kept gone-unpushed; say 'an unpushed branch survives a directory that is already gone' $?

# --- failing quietly ---------------------------------------------------------------------------
run "" "$repo"; say 'an empty worktree_path does nothing' $?
run "$tmp/never-existed" "$tmp"; say 'a path outside any repo does nothing' $?

jq -n '{hook_event_name:"WorktreeRemove"}' | bash "$HOOK" >/dev/null 2>&1
say 'a payload with no fields does nothing' $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

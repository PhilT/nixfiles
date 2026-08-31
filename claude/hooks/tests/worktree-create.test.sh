#!/usr/bin/env bash
# Tests for hooks/worktree-create.sh. Run: bash ~/.claude/hooks/tests/worktree-create.test.sh
#
# The hook replaces Claude Code's worktree creation. Claude Code does NOT fall back when the
# hook exits 0 with empty stdout: it reports "hook succeeded but returned no worktree path" and
# aborts. So the contract is that every run either creates the worktree and prints its path, or
# exits non-zero with a reason on stderr. These check both halves, and that the branch takes the
# worktree name with no prefix.
#
# Each case uses its own worktree name: a name already checked out elsewhere cannot be checked
# out again, so sharing one would fail every case after the first for the wrong reason.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/worktree-create.sh}"
pass=0
fail=0
RC=0
OUT=""

say() {
  if [ "$2" = 0 ]; then pass=$((pass + 1)); printf 'ok    %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Sets RC and OUT in this shell; a command substitution would lose the exit code.
run() {
  jq -n --arg c "$1" --arg n "$2" \
    '{session_id:"t",hook_event_name:"WorktreeCreate",cwd:$c,name:$n}' \
    | bash "$HOOK" >"$tmp/stdout" 2>/dev/null
  RC=$?
  OUT=$(cat "$tmp/stdout")
}

# An origin to branch from, so the `fresh` base ref resolves.
origin="$tmp/origin.git"
git init -q --bare -b main "$origin"
root="$tmp/zuno"
mkdir -p "$root"
repo="$root/mono"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo x > "$repo/a.txt"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" remote add origin "$origin"
git -C "$repo" push -q origin main
git -C "$repo" remote set-head origin main

# --- no location file: Claude Code's own default location ------------------------------------
run "$repo" default-a
[ "$RC" = 0 ]; say 'a repo with no location file still creates a worktree' $?
[ "$OUT" = "$repo/.claude/worktrees/default-a" ]
say 'it defaults to <repo-root>/.claude/worktrees and prints the path' $?
[ -d "$repo/.claude/worktrees/default-a" ]; say 'the worktree exists there' $?

# --- the branch takes the worktree name, with no prefix --------------------------------------
[ "$(git -C "$repo/.claude/worktrees/default-a" rev-parse --abbrev-ref HEAD)" = default-a ]
say 'the branch is named exactly after the worktree, no prefix' $?

# --- location file one directory above the repo (zuno's shape) -------------------------------
mkdir -p "$root/.claude"
echo "$root/worktrees" > "$root/.claude/worktree-location.txt"

run "$repo" feature-a
[ "$RC" = 0 ]; say 'creating with a location file exits 0' $?
[ "$OUT" = "$root/worktrees/feature-a" ]
say 'it reports the relocated path' $?
[ -d "$root/worktrees/feature-a" ]; say 'the worktree exists at the new location' $?
[ ! -d "$repo/.claude/worktrees/feature-a" ]; say 'nothing is created at the default path' $?

# --- an existing branch is reused rather than recreated --------------------------------------
git -C "$repo" branch -q existing-branch
run "$repo" existing-branch
[ "$RC" = 0 ] && [ -d "$root/worktrees/existing-branch" ]
say 'an existing branch is checked out rather than recreated' $?

# --- a non-empty destination is a hard failure -----------------------------------------------
mkdir -p "$root/worktrees/occupied"
echo content > "$root/worktrees/occupied/file.txt"
run "$repo" occupied
[ "$RC" = 1 ]; say 'a non-empty destination refuses rather than clobbering' $?

# --- an empty destination directory is reused, not refused -----------------------------------
mkdir -p "$root/worktrees/empty-dir"
run "$repo" empty-dir
[ "$RC" = 0 ] && [ -n "$OUT" ]; say 'an empty leftover directory is created into' $?

# --- a relative location is not guessed at; it takes the default -----------------------------
echo 'relative/path' > "$root/.claude/worktree-location.txt"
run "$repo" feature-b
[ "$RC" = 0 ] && [ "$OUT" = "$repo/.claude/worktrees/feature-b" ]
say 'a relative location is ignored and the default used' $?
echo "$root/worktrees" > "$root/.claude/worktree-location.txt"

# --- baseRef: head branches from local HEAD, fresh from origin's default ---------------------
git -C "$repo" checkout -q -b local-ahead
echo y > "$repo/b.txt"
git -C "$repo" add b.txt
git -C "$repo" commit -qm "local only"
ahead=$(git -C "$repo" rev-parse HEAD)
git -C "$repo" checkout -q main

mkdir -p "$repo/.claude"
jq -n '{worktree:{baseRef:"head"}}' > "$repo/.claude/settings.json"
git -C "$repo" checkout -q local-ahead
run "$repo" from-head
git -C "$repo" checkout -q main
[ "$(git -C "$root/worktrees/from-head" rev-parse HEAD)" = "$ahead" ]
say 'baseRef head branches from the current local HEAD' $?

jq -n '{worktree:{baseRef:"fresh"}}' > "$repo/.claude/settings.json"
run "$repo" from-origin
[ "$(git -C "$root/worktrees/from-origin" rev-parse HEAD)" = "$(git -C "$repo" rev-parse origin/main)" ]
say 'baseRef fresh branches from origin default' $?
rm -f "$repo/.claude/settings.json"

# --- failing loudly rather than silently ------------------------------------------------------
mkdir -p "$tmp/not-a-repo"
run "$tmp/not-a-repo" x
[ "$RC" = 1 ] && [ -z "$OUT" ]; say 'a cwd outside any repo fails with no path printed' $?

jq -n '{hook_event_name:"WorktreeCreate"}' | bash "$HOOK" >"$tmp/stdout" 2>/dev/null
RC=$?; OUT=$(cat "$tmp/stdout")
[ "$RC" = 1 ] && [ -z "$OUT" ]; say 'a payload with no cwd or name fails rather than printing nothing' $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

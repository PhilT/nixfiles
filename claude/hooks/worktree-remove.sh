#!/usr/bin/env bash
# WorktreeRemove hook: finish the teardown that default removal leaves half done, and stop it
# where it would cost work.
#
# Claude Code removes the directory itself, including one worktree-create.sh relocated, but it
# leaves the branch behind: after ExitWorktree removed /data/work/zuno/worktrees/NA-payload-probe
# on 2026-08-30, the branch of the same name was still there and had to go by hand.
#
# Deliberately not the teardown from the docs. That one runs `worktree remove --force`, falls
# back to `rm -rf`, and deletes the branch with `-D`, so a worktree holding work loses it at
# session exit. Here a worktree is dismantled only when it holds nothing that exists nowhere
# else: no uncommitted changes, and no commits that are absent from every remote. Delivery in
# this repo is a branch pushed and merged through a PR, so a branch whose commits have not
# reached a remote is the whole of that work, and the session exiting is not consent to drop it.
# Nothing is ever removed with rm -rf, and the branch goes only through `git branch -d`.
#
# The event cannot block and its exit code is swallowed, so every path exits 0 and anything
# worth reading goes to stderr.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

input=$(cat)
wt=$(printf '%s' "$input" | jq -r '.worktree_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$wt" ] || exit 0

# The directory may already be gone by the time this fires, so fall back to the session's own
# directory to find the checkout.
repo=""
for probe in "$wt" "$cwd"; do
  [ -n "$probe" ] && [ -d "$probe" ] || continue
  gc=$(cd "$probe" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null) || continue
  gc=$(cd "$probe" 2>/dev/null && cd "$gc" 2>/dev/null && pwd -P) || continue
  repo=$(dirname "$gc")
  break
done
[ -n "$repo" ] || exit 0

# The payload names only the path, never the branch, so ask the worktree registry which branch
# that path has out. The last path segment is not it whenever the two differ: a slash-named
# worktree `trees/feat/probe` is on `feat/probe`, and a repo that prefixes its branch names has
# every worktree in that position. Guessing skips both protections below and orphans the branch.
# The registry holds the entry whenever this hook does the removal itself; the segment is the
# fallback for a worktree Claude Code has already removed, where there is nothing left to ask.
branch_at() {
  local target line current=""
  target=$(readlink -m "$1")
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) current=$(readlink -m "${line#worktree }") ;;
      "branch refs/heads/"*)
        if [ "$current" = "$target" ]; then
          printf '%s\n' "${line#branch refs/heads/}"
          return 0
        fi ;;
    esac
  done < <(git -C "$repo" worktree list --porcelain 2>/dev/null)
  return 1
}

name=$(branch_at "$wt") || name=${wt##*/}
[ -n "$name" ] || exit 0

if [ -d "$wt" ] && [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
  echo "worktree-remove: $wt has uncommitted changes, so it and branch $name are left alone." >&2
  exit 0
fi

if git -C "$repo" rev-parse --verify --quiet "refs/heads/$name" >/dev/null 2>&1 \
   && [ -n "$(git -C "$repo" log --oneline "$name" --not --remotes 2>/dev/null | head -1)" ]; then
  echo "worktree-remove: branch $name has commits on no remote, so it and $wt are left alone." >&2
  exit 0
fi

if [ -d "$wt" ]; then
  git -C "$repo" worktree remove "$wt" >/dev/null 2>&1
fi

git -C "$repo" worktree prune >/dev/null 2>&1

if [ -d "$wt" ]; then
  echo "worktree-remove: could not remove $wt, so branch $name is left alone." >&2
  exit 0
fi

git -C "$repo" branch -d "$name" >/dev/null 2>&1 \
  || echo "worktree-remove: kept branch $name, git refused to delete it." >&2

exit 0

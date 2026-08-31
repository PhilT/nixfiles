#!/usr/bin/env bash
# WorktreeCreate hook: decide where a new worktree goes, create it, and print its path.
#
# Claude Code has no setting for worktree placement. `worktree.location` exists but its own
# description says the CLI does not read it, and there is no `worktreeDir`. Replacing creation
# through this hook is the documented way, so the placement is decided here.
#
# A repo chooses its destination directory (absolute) in .claude/worktree-location.txt, looked
# for at the repo root and then one directory above it. The second candidate is zuno's shape,
# where the repo is /data/work/zuno/mono and .claude sits at /data/work/zuno. A repo without
# the file gets <repo-root>/.claude/worktrees, which is Claude Code's own default location.
#
# THE HOOK MUST ALWAYS PRINT A PATH. Claude Code does not fall back to its own creation logic
# when this hook exits 0 with empty stdout: it reports "hook succeeded but returned no worktree
# path" and aborts, leaving the session unable to start any worktree. So every branch that can
# reach the end either creates the worktree and prints where it is, or exits non-zero with a
# message saying why.
#
# Branch naming takes the payload name, which is what the default does too. The base ref
# follows the `worktree.baseRef` setting read from .claude/settings.json then
# ~/.claude/settings.json: `head` bases on the current local HEAD, anything else (including
# unset) bases on origin's default branch, matching Claude Code's `fresh` default.
set -uo pipefail

fail() { echo "worktree-create: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is not on PATH; cannot read the hook payload."

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
name=$(printf '%s' "$input" | jq -r '.name // empty')
[ -n "$cwd" ] || fail "payload carried no cwd."
[ -n "$name" ] || fail "payload carried no worktree name."
[ -d "$cwd" ] || fail "payload cwd does not exist: $cwd"

# The payload names the worktree and the session's directory, not the repo, so the checkout is
# found from cwd: the common git dir's parent is the main checkout even when cwd is a worktree.
gc=$(cd "$cwd" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null) \
  || fail "$cwd is not inside a git repository."
gc=$(cd "$cwd" 2>/dev/null && cd "$gc" 2>/dev/null && pwd -P) \
  || fail "could not resolve the git common directory of $cwd."
repo_root=$(dirname "$gc")
[ -d "$repo_root" ] || fail "resolved repo root does not exist: $repo_root"

location=""
for candidate in "$repo_root/.claude/worktree-location.txt" \
                 "$(dirname "$repo_root")/.claude/worktree-location.txt"; do
  if [ -r "$candidate" ]; then
    location=$(head -n1 "$candidate" | tr -d '[:space:]')
    break
  fi
done
case "$location" in
  /*) ;;
  *) location="$repo_root/.claude/worktrees" ;;   # unset, or not absolute: Claude Code's default
esac

dest="$location/$name"

if [ -e "$dest" ]; then
  if [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
    fail "$dest already exists and is not empty; refusing to create over it."
  fi
  rmdir "$dest" 2>/dev/null || fail "$dest exists and could not be removed."
fi

mkdir -p "$location" 2>/dev/null || fail "could not create $location."

# baseRef: project settings win over user settings; `head` means the current local HEAD.
base_ref=""
for settings in "$repo_root/.claude/settings.json" "$HOME/.claude/settings.json"; do
  if [ -r "$settings" ]; then
    value=$(jq -r '.worktree.baseRef // empty' "$settings" 2>/dev/null)
    if [ -n "$value" ]; then base_ref=$value; break; fi
  fi
done

if [ "$base_ref" = "head" ]; then
  base=HEAD
else
  git -C "$repo_root" fetch --quiet origin 2>/dev/null
  base=$(git -C "$repo_root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  [ -n "$base" ] || base=origin/main
fi

if git -C "$repo_root" rev-parse --verify --quiet "refs/heads/$name" >/dev/null 2>&1; then
  git -C "$repo_root" worktree add "$dest" "$name" >/dev/null 2>&1 \
    || fail "git worktree add $dest $name failed."
else
  git -C "$repo_root" worktree add -b "$name" "$dest" "$base" >/dev/null 2>&1 \
    || fail "git worktree add -b $name $dest $base failed."
fi

[ -d "$dest" ] || fail "git reported success but $dest does not exist."

echo "$dest"

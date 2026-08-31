#!/usr/bin/env bash
# PreToolUse (Edit|Write|NotebookEdit): refuse a file edit made from a main checkout.
#
# Registered globally, and it limits itself: it fires only in a repo that already has at least
# one worktree, which is what "this project uses the worktree model" looks like on disk. A
# scratch repo where editing the checkout directly is normal never has one, so it is never
# refused, and nothing needs opting in.
#
# Self-limiting rather than opt-in because a project's own .claude/settings.json is not always
# read: zuno doesn't track .claude/, so none of its worktrees has one and a per-project
# registration there reaches only sessions sitting in the checkout itself. A global hook that
# decides from git state reaches every session in both repos.
#
# The test is the session's own working directory: git-dir == git-common-dir means the main
# checkout, and they differ in a worktree. That also catches a working tree attached by a
# gitfile rather than by `git worktree add`, which is how /data/work/zuno resolves to the mono
# checkout: git run from there is git run on main, and this refuses edits from it too.
#
# Containment is somebody else's job. Whether a worktree session may write into a *different*
# tree is handled by worktree-containment.sh, which enumerates `git worktree list` and refuses
# on the target rather than on the session. Keeping the two apart means this file has one rule
# and no path arithmetic.
#
# It only sees the Edit/Write/NotebookEdit tools, not files written via Bash (sed, >), so it
# is a strong nudge rather than a wall; a project's pre-commit hook is the backstop at commit
# time. ~/.claude/hooks/no-heredoc.sh exists to keep file creation on the tool path.
set -euo pipefail

gd=$(git rev-parse --git-dir 2>/dev/null) || exit 0        # not a repo: nothing to enforce
gc=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
# Both are canonicalised before comparing. Git mixes the two forms by working directory: from
# the top of a main checkout both come back `.git`, but from a subdirectory of it --git-dir is
# absolute and --git-common-dir is `../.git`, so comparing them raw reads a main-checkout
# session as a worktree and lets the edit through. Each is relative to the cwd, so cd resolves
# it correctly from wherever the session sits.
gd=$(cd "$gd" 2>/dev/null && pwd -P) || exit 0
gc=$(cd "$gc" 2>/dev/null && pwd -P) || exit 0
[ "$gd" = "$gc" ] || exit 0                                # worktree session: allowed

trees=$(git worktree list --porcelain 2>/dev/null | grep -c '^worktree ') || trees=0
[ "$trees" -gt 1 ] || exit 0                               # no worktrees: not this model

cat >&2 <<'MSG'
Refused: this session is in the main checkout, and this project keeps all file work in a
worktree. Start a worktree first and make the change there.
  EnterWorktree, or: git worktree add <worktrees-dir>/<name> -b <branch>
MSG
exit 2

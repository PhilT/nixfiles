#!/usr/bin/env bash
# PreToolUse (Edit|Write|NotebookEdit): refuse an edit that lands in this repository but
# outside the worktree the session is in.
#
# This is the layer that replaces Claude Code's `worktree.bgIsolation`, which is off because
# it refused on a parse rather than on a risk (166 commands refused across two repos, none of
# them a cross-worktree write). The check here is on the target, not on the command's shape:
# resolve the path the tool would write, and refuse only when it belongs to a different tree
# of the same repository. Unresolvable is not a reason to refuse, so nothing is blocked for
# merely looking complicated.
#
# The trees come from `git worktree list`, never from the layout. Inferring the repo root and
# prefix-testing against it looks equivalent and is not: zuno keeps worktrees in three places
# (<root>/.claude/worktrees, <root>/worktrees, and <checkout>/.claude/worktrees), and only the
# last sits under the main checkout, so a prefix test silently covered 2 of its 10 trees.
# Matching is longest-prefix, because a worktree can sit inside the main checkout and a target
# there belongs to the worktree, not to the checkout that contains it.
#
# Scope is deliberately narrow. A session in the main checkout gets no opinion here: whether
# editing there is allowed is a project's own policy, enforced by require-worktree.sh where a
# project opts in. Paths outside the repository (/tmp, a job's scratch directory, another
# project) pass.
#
# It sees only the Edit/Write tools, not a shell redirect, so it is a guard on the path Claude
# is told to use rather than a wall; ~/.claude/hooks/no-heredoc.sh exists to keep file
# creation on that path.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
# NotebookEdit names its target notebook_path; the other edit tools use file_path. Reading
# only file_path let a notebook be written into a sibling worktree unchecked.
target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$target" ] || exit 0
case "$target" in /*) ;; *) exit 0 ;; esac   # relative resolves against cwd: inside by construction

gd=$(git rev-parse --git-dir 2>/dev/null) || exit 0
gc=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
# Canonicalise before comparing: from a subdirectory of a main checkout --git-dir is absolute
# while --git-common-dir is `../.git`, so a raw comparison reads that session as a worktree and
# this hook starts giving an opinion where its header says it gives none.
gd=$(cd "$gd" 2>/dev/null && pwd -P) || exit 0
gc=$(cd "$gc" 2>/dev/null && pwd -P) || exit 0
[ "$gd" != "$gc" ] || exit 0                 # main checkout: project policy, not ours

own=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
own=$(readlink -m "$own")
target=$(readlink -m "$target")

# The worktree whose path is the longest prefix of the target wins; a worktree nested inside
# the main checkout would otherwise be judged as part of it.
owner=""
while IFS= read -r line; do
  case "$line" in worktree\ *) ;; *) continue ;; esac
  wt=$(readlink -m "${line#worktree }")
  case "$target" in
    "$wt"/*)
      if [ "${#wt}" -gt "${#owner}" ]; then owner=$wt; fi ;;
  esac
done < <(git worktree list --porcelain 2>/dev/null)

[ -n "$owner" ] || exit 0                    # outside every tree of this repo
[ "$owner" != "$own" ] || exit 0             # our own worktree

cat >&2 <<MSG
Refused: this edit targets
  $target
which belongs to
  $owner
not to the worktree this session is in
  $own

Editing another tree changes files you are not on, and the change will not appear in your
branch. Work under $own. If the change really belongs to the other tree, leave it to the
session that owns it.
MSG
exit 2

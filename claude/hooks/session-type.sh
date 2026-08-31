#!/usr/bin/env bash
# UserPromptSubmit hook: report two independent things each turn so they aren't re-derived,
#   - checkout: main checkout vs worktree (git-dir vs git-common-dir, read from the session's
#     own cwd, so a worktree is detected even though this script lives elsewhere);
#   - attachment: attended vs a background run (CLAUDE_JOB_DIR is set for background jobs).
# Checkout decides where work may happen; attachment decides the ask-vs-assume posture. They
# are orthogonal (a background session can hold the main checkout), which is why both are
# reported.
#
# How the work is delivered is the one repo-specific part, and it is read from a file rather
# than written here, because the two repos that use this disagree completely: pacent squashes
# to one commit and pushes straight to main, zuno keeps a branch per ticket and opens a draft
# PR, having been told not to squash, amend or push unless asked. A hook emitting either
# instruction in the other repo would be worse than emitting none.
#
# The text is the <!-- session-delivery --> range of CLAUDE.md, looked for in the session's own
# tree first, then one directory above the main checkout. A CLAUDE.md without the markers does
# not end the search: zuno's worktrees each carry the repo's own tracked CLAUDE.md, which has
# none, and the marked one sits at /data/work/zuno, above the repo. The main checkout's own
# CLAUDE.md is not a third candidate: from the checkout it is already the first one, and from a
# worktree the tracked copy carried into that worktree holds the same content.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

gd=$(git rev-parse --git-dir 2>/dev/null) || exit 0
gc=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
# Both come back relative in a main checkout and absolute in a worktree, so canonicalise
# before comparing: `.git` and `/abs/repo/.git` are the same directory.
gd=$(cd "$gd" 2>/dev/null && pwd -P) || exit 0
gc=$(cd "$gc" 2>/dev/null && pwd -P) || exit 0
root=$(dirname "$gc")

own=$(git rev-parse --show-toplevel 2>/dev/null) || own=$root

delivery=""
for candidate in "$own/CLAUDE.md" \
                 "$(dirname "$root")/CLAUDE.md"; do
  [ -r "$candidate" ] || continue
  delivery=$(sed -n '/<!-- session-delivery -->/,/<!-- \/session-delivery -->/p' "$candidate" \
    | sed '1d;$d' | tr '\n' ' ' | sed 's/  */ /g; s/ $//')
  if [ -n "$delivery" ]; then break; fi
done

if [ -n "${CLAUDE_JOB_DIR:-}" ]; then
  posture="Background run: prefer a reasonable assumption and record it in the end report; flag an interactive (design or Q&A) request before proceeding."
else
  posture="Attended: ask when a design choice is genuinely unclear rather than guessing."
fi

trees=$(git worktree list --porcelain 2>/dev/null | grep -c '^worktree ') || trees=0

if [ "$gd" = "$gc" ]; then
  if [ "$trees" -gt 1 ]; then
    place="Main checkout $root. All file work happens in a worktree, so editing or creating files here is blocked. Start a worktree before any change (reading, planning and read-only commands are fine here)."
  else
    place="Main checkout $root, and this repo has no worktrees, so file work here is allowed."
  fi
else
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  own=$(git rev-parse --show-toplevel 2>/dev/null)
  place="Worktree $own on '$branch'. Read, grep and run commands under that path; the main checkout at $root holds a different branch and answers from it are wrong for this session."
fi

jq -n --arg text "[session] $place $delivery $posture" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:($text|gsub("  +";" "))}}'

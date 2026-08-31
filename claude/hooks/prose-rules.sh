#!/usr/bin/env bash
# PreToolUse (Edit|Write): refuse prose that breaks the writing rules at the moment it is
# written, rather than at commit time. A pre-commit check catches em dashes only once a whole
# change is staged, so the fix comes long after the sentence; this catches them in the edit
# that introduces them, and adds the banned-word list.
#
# Registered globally, because the writing rules in ~/.claude/CLAUDE.md are not tied to one
# project: an em dash is as unwanted in a work repo's docs as in a personal one.
#
# Scope: .md and .erb targets, and only the text this call adds (Edit's new_string, Write's
# content), so the existing corpus is left alone. A word wrapped in backticks passes, which is
# how a doc names the word it bans. Exit 2 blocks the tool call and shows this message.
#
# The word list is deliberately short: only words with no ordinary technical use. The
# context-dependent ones the writing rules also name (anchor, gate, floor, surface, land,
# fold, clean, powerful) stay a matter of judgment, because a hook can't tell "Math.floor"
# or "surface area" from the prose sense, and a guard that cries wolf gets ignored.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
case "$path" in
  *.md|*.erb) ;;
  *) exit 0 ;;
esac

added=$(printf '%s' "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[ -n "$added" ] || exit 0

# Drop code before judging it as prose. Fenced blocks go first: the inline-span removal below
# is line-oriented, so a shell block holding an em dash or one of the words was refused as
# writing. An opening fence with no closing one takes the rest of the fragment with it, which
# is what an Edit that adds only the first half of a block looks like.
prose=$(printf '%s' "$added" | awk '
  /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
  !fenced
' | sed 's/`[^`]*`//g')

banned='delve|leverage|robust|comprehensive|seamless|transformative|load-bearing|unlock|wobble|mint|actually|genuinely|honestly|frankly'
fail=0

if printf '%s' "$prose" | grep -qP '\x{2014}'; then
  echo "prose-rules: em dash (U+2014) in the text being written; use a colon, comma, or parentheses:" >&2
  printf '%s' "$prose" | grep -nP '\x{2014}' | head -5 >&2
  fail=1
fi

if printf '%s' "$prose" | grep -qiP "\\b(${banned})\\b"; then
  echo "prose-rules: banned word in the text being written; fix it by being concrete, not by picking a synonym:" >&2
  printf '%s' "$prose" | grep -niP "\\b(${banned})\\b" | head -5 >&2
  fail=1
fi

[ "$fail" -eq 0 ] && exit 0

cat >&2 <<'MSG'
Rewrite the offending text and make the edit again. To name one of these words in a doc that
is about the rule itself, wrap it in backticks.
MSG
exit 2

#!/usr/bin/env bash
# PreToolUse (Edit|Write): two rules on Ruby files, with different reach. Ruby means .rb, .rake
# and Rakefile, all three of which rubocop lints.
#
# Rule 1, `# rubocop:disable` and `# rubocop:todo`, applies wherever a .rubocop.yml sits at or
# above the file, inside the same repository. Rule 2 does not depend on it. That is what "a Ruby project that lints" looks like on disk, so nothing
# needs to opt in: zuno's api/ and the whole of pacent both qualify, and both already hold zero
# disables, so the rule records existing practice rather than imposing a new one.
#
# Rule 2, no new comments, applies only where a repo asks for it, by way of a
# .claude/no-new-comments file. The two repos disagree about comments and both positions are
# considered: zuno wants them refactored away, pacent keeps comments that explain an absence
# ("a Smith machine is deliberately absent"), record a rejected alternative, carry domain
# knowledge, or state a consequence in another file. A grep for `^\s*#` cannot tell those from a
# restatement of the line below, so the choice is per repo, not per comment.
#
# The marker is looked for in the target's own worktree, then the checkout root, then one
# directory above it, matching session-type.sh. The last candidate is zuno's shape, where the
# repo is /data/work/zuno/mono and .claude sits at /data/work/zuno, so the walk has to leave the
# repo to find it. Only presence counts; the file's text is for whoever finds it.
#
# Global because the per-project registration this replaces never fired. It lived in
# /data/work/zuno/.claude/settings.json under the relative command path
# `.claude/hooks/block-code-violations.sh`, and zuno does not track .claude/, so no worktree
# carries the settings file or the script. All zuno file work happens in a worktree, and
# require-worktree.sh refuses edits from the checkout, so no session was left where it could run.
#
# Scope is the text this call adds (Edit's new_string, Write's content), so existing comments in
# the file are left alone. Both rules are about adding.
#
# It sees only the Edit/Write tools, not a shell redirect, so it is a guard on the path Claude is
# told to use rather than a wall. Danger's rubocop_disabled_checker.rb is the backstop at PR time.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

case "$file_path" in
  *.rb|*.rake|Rakefile|*/Rakefile) ;;
  *) exit 0 ;;
esac

dir=${file_path%/*}
[ "$dir" = "$file_path" ] && dir=$PWD
while [ -n "$dir" ] && [ ! -d "$dir" ]; do dir=${dir%/*}; done
[ -n "$dir" ] || exit 0

own=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
own=$(cd "$own" 2>/dev/null && pwd -P) || exit 0
d=$(cd "$dir" 2>/dev/null && pwd -P) || exit 0

linted=""
while :; do
  if [ -f "$d/.rubocop.yml" ]; then
    linted=$d
    break
  fi
  [ "$d" = "$own" ] && break
  [ "$d" = "/" ] && break
  d=${d%/*}
  [ -n "$d" ] || d=/
done

content=""
if [ "$tool_name" = "Edit" ]; then
  content=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""')
elif [ "$tool_name" = "Write" ]; then
  content=$(printf '%s' "$input" | jq -r '.tool_input.content // ""')
fi
[ -n "$content" ] || exit 0

# The space after the `#` is optional and rubocop reads `todo` the same way it reads `disable`,
# so both forms are matched rather than the one literal string.
if [ -n "$linted" ] && printf '%s' "$content" | grep -qE "#[[:space:]]*rubocop:(disable|todo)"; then
  cat >&2 <<'MSG'
❌ Rubocop Disable Blocked

You attempted to add a `# rubocop:disable` or `# rubocop:todo` comment.

Instead of disabling the rule, please:
1. Fix the underlying code to comply with the Rubocop rule
2. Refactor the code structure if needed
3. Ask the user for guidance if you're unsure how to proceed

A violation usually means the code needs restructuring, and a disable comment hides that
for as long as the file lives. Neither repo holds a single disable today.
MSG
  exit 2
fi

# A worktree gets an absolute path back, a main checkout a path relative to the -C directory
# (`.git`, or `../.git` from a subdirectory), so resolve it against $dir before canonicalising.
common=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null) || exit 0
case "$common" in /*) ;; *) common="$dir/$common" ;; esac
common=$(cd "$common" 2>/dev/null && pwd -P) || exit 0
root=$(dirname "$common")

opted_in=""
for candidate in "$own/.claude/no-new-comments" \
                 "$root/.claude/no-new-comments" \
                 "$(dirname "$root")/.claude/no-new-comments"; do
  if [ -e "$candidate" ]; then
    opted_in=$candidate
    break
  fi
done
[ -n "$opted_in" ] || exit 0

blocked_comments=$(printf '%s' "$content" | grep -E '^\s*#' | grep -vE '^\s*#\s*(frozen_string_literal|encoding|warn_indent|TODO|FIXME|HACK|NOTE|rubocop:enable|!|@param|@return|@raise|@yield|@see|@deprecated|@example|@author|@since|@option)' || true)

if [ -n "$blocked_comments" ]; then
  cat >&2 <<MSG
❌ Unnecessary Comment Detected

You attempted to add a comment to the code:

$blocked_comments

Comments are generally unnecessary and indicate code that needs refactoring.

Important: Do NOT remove existing comments from the codebase.
This rule only applies to adding NEW comments.

Instead of adding a comment:
1. Rename variables/methods to be more descriptive
2. Extract complex logic into well-named methods
3. Simplify the code structure to make it self-explanatory

If you believe this is a truly necessary "why" comment (rare cases like
non-obvious business rules or workarounds):
1. Use AskUserQuestion to explain why the comment is needed
2. If the user approves, they will add it manually

Allowed comment types (no need to ask):
- Magic comments: # frozen_string_literal: true
- Technical debt: # TODO:, # FIXME:, # HACK:, # NOTE:

This rule is on because $opted_in exists.
See CLAUDE.md "Code Comments Policy" section for details.
MSG
  exit 2
fi

exit 0

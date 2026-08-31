#!/usr/bin/env bash
# PreToolUse (Bash): refuse a `devbox run` carrying multi-line code.
#
# devbox generates .devbox/gen/scripts/.cmd.sh, whose last line is `eval $DEVBOX_RUN_CMD`.
# Rebuilding the command that way turns embedded newlines into a literal `\n` and drops the
# arguments after `bash -c '…'`, so multi-line Ruby/SQL/shell reaches the interpreter
# corrupted, usually as a syntax error but sometimes as a script that runs and does the
# wrong thing. No devbox flag avoids the wrapper and the file is regenerated, so the fix is
# to keep multi-line code out of `devbox run`.
#
# Detection: from each real invocation, walk the rest tracking quote state. A newline inside
# quotes is the corruption case. At top level a newline or a `;`/`|`/`&` ends this command,
# so a later unrelated multi-line block doesn't trigger. Locating the invocations is shared
# with devbox-cwd.sh, which keeps `devbox run` written inside a quoted string or a heredoc
# body from counting: writing a doc or a test about the phrase is not running it.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

lib="${BASH_SOURCE[0]%/*}/lib/devbox-scan.sh"
[ -r "$lib" ] || exit 0
# shellcheck source=lib/devbox-scan.sh
. "$lib"

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
case "$cmd" in *devbox*) ;; *) exit 0 ;; esac

scan() {
  local rest=$1
  local state=none i=0 c=""
  local n=${#rest}
  while [ "$i" -lt "$n" ]; do
    c=${rest:i:1}
    case "$state" in
      none)
        case "$c" in
          "'") state=single ;;
          '"') state=double ;;
          $'\n'|';'|'|'|'&') return 1 ;;
        esac ;;
      single)
        case "$c" in
          $'\n') return 0 ;;
          "'") state=none ;;
        esac ;;
      double)
        case "$c" in
          '\') i=$((i + 1)) ;;
          $'\n') return 0 ;;
          '"') state=none ;;
        esac ;;
    esac
    i=$((i + 1))
  done
  return 1
}

while IFS= read -r offset; do
  [ -n "$offset" ] || continue
  rest=${cmd:offset}
  rest=${rest#*run}
  if scan "$rest"; then
    cat >&2 <<'MSG'
Refused: this `devbox run` carries multi-line code. devbox re-parses the command through
`eval $DEVBOX_RUN_CMD`, which turns the newlines into a literal `\n` and drops any argument
after `bash -c '…'`, so the interpreter receives corrupted source.

Write the code to a file and run the file (fastest, and no quoting to get wrong):
  devbox run -- bash -c 'cd /path/to/worktree && bin/rails runner /path/to/script.rb'

If the call must stay inline, bypass the wrapper (about 5x slower per call):
  eval "$(devbox shellenv --init-hook)" && ruby -e '<code>'
MSG
    exit 2
  fi
done < <(devbox_invocations "$cmd")
exit 0

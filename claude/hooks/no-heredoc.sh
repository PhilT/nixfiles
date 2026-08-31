#!/usr/bin/env bash
# PreToolUse (Bash): refuse a heredoc, and point at the Write tool instead.
#
# Two reasons, in order of weight:
#
#   1. The Write tool is the only file-creation path the Edit/Write guards can see. A
#      project's own guard (pacent's require-worktree.sh) refuses a write into another
#      checkout, but it is registered on Edit|Write and a shell redirect goes straight past
#      it. Keeping file creation in the tool keeps it inside that check. This matters more
#      where `worktree.bgIsolation` is off, since the Edit/Write guard is then the layer
#      standing between a background session and a sibling worktree.
#   2. `devbox run` rebuilds the command through `eval $DEVBOX_RUN_CMD`, which flattens
#      embedded newlines and drops the arguments after `bash -c '…'`, so multi-line source
#      reaches the interpreter corrupted (see devbox-inline-code.sh). A heredoc feeding an
#      interpreter through devbox hits this.
#
# There is also no quoting to get wrong: the shell re-splits embedded quotes and parentheses
# at every layer, and the Write tool has no layers.
#
# Where `worktree.bgIsolation` is left on, Claude Code's isolation guard adds a third reason
# by refusing any heredoc body holding a quote inside braces (every Python dict, Ruby hash
# and JSON literal) as "too complex to verify that it stays inside the worktree", a message
# that names the worktree rather than the brace. That reason lapses when the setting is off;
# the two above do not.
#
# Detection is positional, walking quote state, so `<<` inside a quoted string is text and
# not an invocation: writing a doc or a test that quotes a heredoc is not running one, and a
# guard that fires on its own name gets worked around. `<<<` (herestring) is single-line and
# carries no file write, so it is allowed, and a `<<` inside `$(( ))` is a left shift.
#
# Escape hatch: put `heredoc-ok` anywhere in the command to bypass this check.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
case "$cmd" in *'<<'*) ;; *) exit 0 ;; esac
case "$cmd" in *heredoc-ok*) exit 0 ;; esac

# Echo the offset just past the parenthesis that closes the arithmetic expansion or command
# starting at $2, or past the end when it never closes. The caller's own step takes it past the
# second one. Nested parentheses are counted, so `$(( (1<<2) ))` is skipped whole.
_skip_arithmetic() {
  local s=$1 i=$2 n=$3
  local depth=0 c
  i=$((i + 1))                            # the first `(` of the pair
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    case "$c" in
      '(') depth=$((depth + 1)) ;;
      ')') depth=$((depth - 1)); [ "$depth" -le 0 ] && { printf '%s' "$((i + 1))"; return 0; } ;;
    esac
    i=$((i + 1))
  done
  printf '%s' "$n"
}

# A heredoc needs a delimiter word after the operator, so `<<` followed by a digit or an
# operator is a shift or a redirect rather than a heredoc. `<<-`, `<<'EOF'` and `<<"EOF"` all
# count. A delimiter starting with a digit is legal shell and never written, so it is read as
# arithmetic.
_has_delimiter() {
  local s=$1 i=$2 n=$3
  local c
  [ "${s:i:1}" = "-" ] && i=$((i + 1))
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    case "$c" in
      ' '|$'\t') i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  c=${s:i:1}
  case "$c" in
    [A-Za-z_]|"'"|'"'|'\') return 0 ;;
    *) return 1 ;;
  esac
}

# Echo the offset of the first real heredoc operator, or nothing.
first_heredoc() {
  local s=$1
  local state=none i=0 c="" run=0
  local n=${#s}
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    case "$state" in
      none)
        case "$c" in
          "'") state=single ;;
          '"') state=double ;;
          '(')
            # `$((1<<20))` and `((x = 1<<20))` are shifts, not redirects. Skip the whole
            # arithmetic expansion so its `<<` is never read as an operator.
            if [ "${s:i+1:1}" = '(' ]; then
              i=$(_skip_arithmetic "$s" "$i" "$n")
            fi ;;
          '<')
            # Consume the whole run of `<` so `<<<` is judged as one operator, not as a
            # heredoc starting at its second character.
            run=0
            while [ "$((i + run))" -lt "$n" ] && [ "${s:i+run:1}" = '<' ]; do
              run=$((run + 1))
            done
            if [ "$run" = 2 ] && _has_delimiter "$s" "$((i + 2))" "$n"; then
              printf '%s\n' "$i"
              return 0
            fi
            i=$((i + run - 1)) ;;
        esac ;;
      single) [ "$c" = "'" ] && state=none ;;
      double)
        case "$c" in
          '\') i=$((i + 1)) ;;
          '"') state=none ;;
        esac ;;
    esac
    i=$((i + 1))
  done
  return 1
}

first_heredoc "$cmd" >/dev/null || exit 0

cat >&2 <<'MSG'
Refused: this command carries a heredoc. Create the file with the Write tool, then run it:
  Write  /path/to/script.py   (or .rb, .sql)
  Bash   devbox run -- python3 /path/to/script.py

A shell redirect goes straight past the Edit/Write guard that refuses a write into another
checkout; the Write tool stays inside it. `devbox run` also flattens multi-line source, and
the Write tool has none of the quoting layers that re-split embedded quotes and parentheses.

Scratch files belong in this session's job tmp directory when there is one, else /tmp.

If the heredoc is the right tool here (piping a short literal to a command, writing no file),
add `heredoc-ok` anywhere in the command to bypass this check.
MSG
exit 2

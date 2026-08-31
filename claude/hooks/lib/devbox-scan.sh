#!/usr/bin/env bash
# Shared shell-command scanning for the devbox PreToolUse hooks.
#
# Both hooks have to answer the same question first: is this string an actual `devbox run`
# invocation, or is it text that merely contains the phrase? Grepping for the phrase, or
# writing a doc or test that quotes it, used to trip both guards. A guard that fires on its
# own name gets worked around, so the match has to be positional.
#
# The scan walks between the characters that change meaning rather than over every character.
# `${s:i:1}` costs time proportional to i in a UTF-8 locale, so indexing a string position by
# position is quadratic in its length: a 16000-character command took about a second, on every
# Bash tool call, in three separate hooks. Pattern removal (`${rest%%[…]*}`) finds the next
# quote, separator or redirect in one step, so the cost follows the number of those characters
# instead of the length of the command. Ordinary text between them is skipped whole.
#
# Everything here consumes from the head of a shrinking `rest` and never re-slices the original
# string from an offset, because that re-slicing is the quadratic step being removed.

# The characters that end a run of ordinary text: quotes, command separators, and `<` for a
# possible heredoc. Held in a variable so the bracket expression stays readable.
_DEVBOX_META=$'\'";|&({<\n'

# Echo the offset of each `devbox run` sitting where a command can start. Quoted spans and
# heredoc bodies are skipped, so only a real invocation is reported.
devbox_invocations() {
  local s=$1
  local rest=$s pos=0 start=1
  local head skip c j delim tail marker pre q blanks nb

  while [ -n "$rest" ]; do
    if [ "$start" = 1 ]; then
      # A command may begin here. Step over any blanks, then test for the phrase itself.
      blanks=${rest%%[![:blank:]]*}
      nb=${#blanks}
      if [ "$nb" -gt 0 ]; then
        pos=$((pos + nb))
        rest=${rest:nb}
      fi
      if [[ $rest =~ ^devbox[[:space:]]+run([[:space:]]|$) ]]; then
        printf '%s\n' "$pos"
      fi
      start=0
    fi

    # Skip the run of ordinary text before the next character that means something.
    head=${rest%%[$_DEVBOX_META]*}
    if [ "${#head}" = "${#rest}" ]; then
      break                                   # nothing left that can change the state
    fi
    skip=${#head}
    if [ "$skip" -gt 0 ]; then
      pos=$((pos + skip))
      rest=${rest:skip}
    fi

    c=${rest:0:1}
    case "$c" in
      "'")
        # A single-quoted span ends at the next quote; nothing inside it escapes.
        rest=${rest:1}; pos=$((pos + 1))
        head=${rest%%\'*}
        if [ "${#head}" = "${#rest}" ]; then
          rest=""                             # unterminated: the rest is quoted text
        else
          pos=$((pos + ${#head} + 1))
          rest=${rest:${#head}+1}
        fi ;;
      '"')
        rest=${rest:1}; pos=$((pos + 1))
        _devbox_skip_double
        ;;
      ';'|'|'|'&'|'('|'{'|$'\n')
        pos=$((pos + 1)); rest=${rest:1}
        start=1 ;;
      '<')
        _devbox_skip_heredoc ;;
    esac
  done
}

# Consume a double-quoted span from the head of `rest`, leaving `rest` and `pos` just past the
# closing quote. A backslash escapes the character after it, so `\"` does not close the span.
# Callers have already consumed the opening quote.
_devbox_skip_double() {
  local head esc
  while [ -n "$rest" ]; do
    head=${rest%%[\"\\]*}
    if [ "${#head}" = "${#rest}" ]; then
      rest=""                                 # unterminated
      return
    fi
    pos=$((pos + ${#head}))
    rest=${rest:${#head}}
    esc=${rest:0:1}
    if [ "$esc" = '\' ]; then
      pos=$((pos + 2)); rest=${rest:2}        # the escaped character is literal
    else
      pos=$((pos + 1)); rest=${rest:1}        # the closing quote
      return
    fi
  done
}

# Handle a `<` at the head of `rest`. A `<<` that is not `<<<` opens a heredoc, whose body runs
# to a line holding the delimiter; that body is skipped whole so text quoted inside it is never
# read as a command. Anything else is an ordinary redirect and is stepped over.
_devbox_skip_heredoc() {
  local j delim tail marker pre q ch

  if [ "${rest:0:2}" != "<<" ] || [ "${rest:2:1}" = "<" ]; then
    pos=$((pos + 1)); rest=${rest:1}
    return
  fi

  j=2
  [ "${rest:j:1}" = "-" ] && j=$((j + 1))
  q=${rest:j:1}
  case "$q" in "'"|'"') j=$((j + 1)) ;; esac
  delim=""
  while :; do
    ch=${rest:j:1}
    case "$ch" in
      [A-Za-z0-9_]) delim="$delim$ch"; j=$((j + 1)) ;;
      *) break ;;
    esac
  done

  if [ -z "$delim" ]; then
    pos=$((pos + 1)); rest=${rest:1}          # `<<` with no delimiter: treat as a redirect
    return
  fi

  tail=${rest:j}
  marker=$'\n'$delim
  pre=${tail%%"$marker"*}
  if [ "$pre" = "$tail" ]; then
    pos=$((pos + ${#rest}))
    rest=""                                   # no closing delimiter: the body runs to the end
  else
    pos=$((pos + j + ${#pre} + ${#marker}))
    rest=${rest:j+${#pre}+${#marker}}
  fi
}

# Emit each top-level command in $1, NUL-separated, splitting on `;`, `|`, `&` and newlines
# that are not inside quotes. Heredoc bodies stay attached to the command that opened them
# rather than being split into commands of their own, so a doc or test quoting a command is
# never mistaken for running it. Segments can contain newlines, hence the NUL separator.
shell_segments() {
  local s=$1
  local rest=$s pos=0 seg=""
  local head skip c before

  while [ -n "$rest" ]; do
    head=${rest%%[$_DEVBOX_META]*}
    if [ "${#head}" = "${#rest}" ]; then
      seg="$seg$rest"
      rest=""
      break
    fi
    skip=${#head}
    if [ "$skip" -gt 0 ]; then
      seg="$seg$head"
      pos=$((pos + skip))
      rest=${rest:skip}
    fi

    c=${rest:0:1}
    case "$c" in
      "'")
        before=$pos
        seg="$seg'"
        rest=${rest:1}; pos=$((pos + 1))
        head=${rest%%\'*}
        if [ "${#head}" = "${#rest}" ]; then
          seg="$seg$rest"; rest=""
        else
          seg="$seg$head'"
          pos=$((pos + ${#head} + 1))
          rest=${rest:${#head}+1}
        fi ;;
      '"')
        before=$pos
        seg="$seg\""
        rest=${rest:1}; pos=$((pos + 1))
        _devbox_segments_double ;;
      ';'|'|'|'&'|$'\n')
        printf '%s\0' "$seg"
        seg=""
        pos=$((pos + 1)); rest=${rest:1} ;;
      '(' | '{')
        # Not a separator for this function: keep it as part of the current segment.
        seg="$seg$c"
        pos=$((pos + 1)); rest=${rest:1} ;;
      '<')
        before=${#rest}
        _devbox_skip_heredoc
        seg="$seg${s:pos-(before-${#rest}):before-${#rest}}" ;;
    esac
  done

  [ -n "$seg" ] && printf '%s\0' "$seg"
  return 0
}

# The double-quote skip for shell_segments, which has to keep the text it passes over.
_devbox_segments_double() {
  local head esc
  while [ -n "$rest" ]; do
    head=${rest%%[\"\\]*}
    if [ "${#head}" = "${#rest}" ]; then
      seg="$seg$rest"; rest=""
      return
    fi
    seg="$seg$head"
    pos=$((pos + ${#head}))
    rest=${rest:${#head}}
    esc=${rest:0:1}
    if [ "$esc" = '\' ]; then
      seg="$seg${rest:0:2}"
      pos=$((pos + 2)); rest=${rest:2}
    else
      seg="$seg\""
      pos=$((pos + 1)); rest=${rest:1}
      return
    fi
  done
}

# Echo the quoted argument of a `-c` flag in $1, so the body of `bash -c '…'` can be walked
# as commands in its own right. Empty when there is none.
shell_dash_c_body() {
  local seg=$1
  if [[ $seg =~ (^|[[:space:]])-c[[:space:]]+\'([^\']*)\' ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
  elif [[ $seg =~ (^|[[:space:]])-c[[:space:]]+\"([^\"]*)\" ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
  fi
}

# Echo the part of $1 that belongs to this command: everything up to the first `;`, `|`, `&`
# or newline that is not inside quotes, so a later unrelated call is judged on its own. A
# newline inside quotes is kept, which is how the inline-code hook spots multi-line source.
devbox_segment() {
  local rest=$1
  local out="" head c esc

  while [ -n "$rest" ]; do
    head=${rest%%[\'\";|&$'\n']*}
    if [ "${#head}" = "${#rest}" ]; then
      out="$out$rest"
      break
    fi
    out="$out$head"
    rest=${rest:${#head}}

    c=${rest:0:1}
    case "$c" in
      "'")
        out="$out'"
        rest=${rest:1}
        head=${rest%%\'*}
        if [ "${#head}" = "${#rest}" ]; then
          out="$out$rest"; rest=""
        else
          out="$out$head'"
          rest=${rest:${#head}+1}
        fi ;;
      '"')
        out="$out\""
        rest=${rest:1}
        while [ -n "$rest" ]; do
          head=${rest%%[\"\\]*}
          if [ "${#head}" = "${#rest}" ]; then
            out="$out$rest"; rest=""
            break
          fi
          out="$out$head"
          rest=${rest:${#head}}
          esc=${rest:0:1}
          if [ "$esc" = '\' ]; then
            out="$out${rest:0:2}"
            rest=${rest:2}
          else
            out="$out\""
            rest=${rest:1}
            break
          fi
        done ;;
      *)
        break ;;                              # an unquoted separator ends this command
    esac
  done

  printf '%s' "$out"
}

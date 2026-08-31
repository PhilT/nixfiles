#!/usr/bin/env bash
# Tests for hooks/lib/devbox-scan.sh. Run:
#   bash ~/.claude/hooks/tests/devbox-scan.test.sh
#
# The library is the shell-command parser behind devbox-cwd.sh, devbox-inline-code.sh and
# git-shared-branch.sh, and until now it was only ever exercised through them. That tests its
# edge cases twice over at the wrong level and its own boundaries not at all: a quoting bug
# shows up as a confusing failure in two hook suites, or in neither, depending on whether
# either happens to pass a string that reaches it.
#
# The four functions and their contracts:
#   devbox_invocations  offsets where `devbox run` sits at a command start
#   shell_segments      the command split into NUL-separated segments
#   shell_dash_c_body   the quoted body of a `-c` flag
#   devbox_segment      the leading part of a string up to the first unquoted separator
set -uo pipefail

LIB="${LIB:-$HOME/.claude/hooks/lib/devbox-scan.sh}"
pass=0
fail=0

say() {
  if [ "$2" = 0 ]; then pass=$((pass + 1)); printf 'ok    %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL  %s (%s)\n' "$1" "${3:-}"; fi
}

# shellcheck source=../lib/devbox-scan.sh
. "$LIB"

# --- devbox_invocations: a real call against the phrase as text ---------------------------
# The whole point of the positional match. A guard that fired on its own name in a doc, a
# grep pattern or a test would get worked around, so text that merely contains the phrase
# must report nothing.
count() { devbox_invocations "$1" | grep -c . || true; }

[ "$(count 'devbox run -- bin/rails test')" = 1 ]
say 'a plain devbox run is one invocation' $?

[ "$(count 'echo "devbox run -- bin/rails test"')" = 0 ]
say 'the phrase inside double quotes is not an invocation' $?

[ "$(count "grep -r 'devbox run' docs/")" = 0 ]
say 'the phrase inside single quotes is not an invocation' $?

[ "$(count 'cd /tmp && devbox run -- ls')" = 1 ]
say 'a devbox run after && is an invocation' $?

[ "$(count 'devbox run -- a; devbox run -- b')" = 2 ]
say 'two invocations separated by a semicolon are both found' $?

[ "$(count 'ls | devbox run -- wc -l')" = 1 ]
say 'a devbox run after a pipe is an invocation' $?

[ "$(count 'echo devbox run')" = 0 ]
say 'the phrase as an argument to another command is not an invocation' $?

[ "$(count 'cat <<EOF
devbox run -- ls
EOF')" = 0 ]
say 'the phrase in a heredoc body is not an invocation' $?

[ "$(count 'ls')" = 0 ]
say 'a command with no devbox run reports nothing' $?

[ "$(count '')" = 0 ]
say 'an empty command reports nothing' $?

# --- shell_segments: splitting on separators, respecting quotes ----------------------------
segs() { shell_segments "$1" | tr '\0' '\n' | grep -c . || true; }

[ "$(segs 'ls')" = 1 ]
say 'a single command is one segment' $?

[ "$(segs 'ls; pwd')" = 2 ]
say 'a semicolon splits into two segments' $?

[ "$(segs 'ls && pwd || true')" = 3 ]
say 'both && and || split segments' $?

[ "$(segs 'echo "a; b"')" = 1 ]
say 'a separator inside double quotes does not split' $?

[ "$(segs "echo 'a; b'")" = 1 ]
say 'a separator inside single quotes does not split' $?

# --- shell_dash_c_body: pulling out a nested command ---------------------------------------
[ "$(shell_dash_c_body "bash -c 'cd /tmp && ls'")" = 'cd /tmp && ls' ]
say 'a single-quoted -c body is extracted' $?

[ "$(shell_dash_c_body 'sh -c "git status"')" = 'git status' ]
say 'a double-quoted -c body is extracted' $?

[ -z "$(shell_dash_c_body 'ls -la')" ]
say 'a command with no -c yields nothing' $?

[ -z "$(shell_dash_c_body '')" ]
say 'an empty string yields nothing' $?

# --- devbox_segment: the leading command only ----------------------------------------------
[ "$(devbox_segment 'ls -la; rm -rf /')" = 'ls -la' ]
say 'a segment stops at the first semicolon' $?

[ "$(devbox_segment 'ls | wc')" = 'ls ' ]
say 'a segment stops at a pipe' $?

[ "$(devbox_segment 'echo "a; b" done')" = 'echo "a; b" done' ]
say 'a quoted separator is kept inside the segment' $?

[ "$(devbox_segment 'ls')" = 'ls' ]
say 'a command with no separator is returned whole' $?

# --- the parser must not go back to walking character by character -------------------------
# `${s:i:1}` costs time proportional to i in a UTF-8 locale, so indexing a string position by
# position is quadratic in its length: this scan used to take 956ms on 16000 characters of
# ordinary text, paid on every Bash tool call in three hooks. It now skips a run of ordinary
# text in one step and takes about 7ms. The bounds below are roughly ten times the measured
# cost, so they catch that regression without failing on a loaded machine.
timed() {                   # timed <string>: echo milliseconds
  local start end
  start=$(date +%s%N)
  devbox_invocations "$1" >/dev/null
  end=$(date +%s%N)
  printf '%s' $(( (end - start) / 1000000 ))
}

plain=$(printf 'x%.0s' $(seq 1 16000))
ms=$(timed "$plain")
[ "$ms" -lt 150 ]
say "16000 characters of ordinary text scan in under 150ms (took ${ms}ms)" $?

# Twice the input for roughly twice the time. Indexing per position would be four times.
plain32=$(printf 'x%.0s' $(seq 1 32000))
ms32=$(timed "$plain32")
[ "$ms32" -lt 250 ]
say "doubling that input does not square the time (32000 chars took ${ms32}ms)" $?

# A long command of ordinary shape: separators and quotes throughout rather than one run of
# text. Still quadratic, because each jump copies what is left of the string, so this bound
# is looser than the one above on purpose.
realistic=""
for _ in $(seq 1 100); do
  realistic="$realistic cd /some/path && devbox run -- bin/rails test file.rb; echo \"x\" |"
done
ms=$(timed "$realistic")
[ "$ms" -lt 600 ]
say "a 7000-character command of ordinary shape scans in under 600ms (took ${ms}ms)" $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

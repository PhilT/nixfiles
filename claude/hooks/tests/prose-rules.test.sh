#!/usr/bin/env bash
# Tests for hooks/prose-rules.sh. Run: bash ~/.claude/hooks/tests/prose-rules.test.sh
#
# Each case feeds the hook a real PreToolUse payload on stdin and asserts the exit code:
# 0 lets the edit through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/prose-rules.sh}"
pass=0
fail=0

DASH=$(printf '—')

# Write payload: file_path + content
check_write() {
  local name=$1 path=$2 text=$3 want=$4 got
  jq -n --arg p "$path" --arg c "$text" \
    '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p,content:$c}}' \
    | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

# Edit payload: file_path + new_string
check_edit() {
  local name=$1 path=$2 text=$3 want=$4 got
  jq -n --arg p "$path" --arg c "$text" \
    '{hook_event_name:"PreToolUse",tool_name:"Edit",tool_input:{file_path:$p,old_string:"x",new_string:$c}}' \
    | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

check_write 'plain prose in a doc is allowed' \
  /r/doc.md 'The seed runs on every deploy.' 0

check_write 'an em dash in a doc is refused' \
  /r/doc.md "The seed runs${DASH}on every deploy." 2

check_write 'a banned word in a doc is refused' \
  /r/doc.md 'This is a robust solution.' 2

check_write 'a banned word in backticks is allowed' \
  /r/doc.md 'Never write `robust` in a sentence.' 0

check_write 'a banned word is caught whatever the case' \
  /r/doc.md 'We should Leverage the cache.' 2

check_write 'a banned word inside a longer word is allowed' \
  /r/doc.md 'The minted coin and the unlockable door.' 0

check_write 'an em dash in an erb template is refused' \
  /r/app/views/x.html.erb "<p>One${DASH}two</p>" 2

check_write 'an em dash in a ruby file is ignored' \
  /r/app/models/x.rb "# One${DASH}two" 0

check_write 'a file with no extension is ignored' \
  /r/Makefile "One${DASH}two" 0

check_edit 'an em dash in an Edit new_string is refused' \
  /r/doc.md "One${DASH}two" 2

check_edit 'plain prose in an Edit new_string is allowed' \
  /r/doc.md 'One and two.' 0

# The backtick stripping is line-oriented, so it only ever matched an inline span. A fenced
# block is code being quoted, not writing, and its contents are not judged as prose.
FENCE='```'
TILDE='~~~'

check_write 'a banned word inside a fenced block is allowed' \
  /r/doc.md "Run it:

${FENCE}sh
grep -rn robust .
${FENCE}

That is all." 0

check_write 'an em dash inside a fenced block is allowed' \
  /r/doc.md "Run it:

${FENCE}sh
echo 'a ${DASH} b'
${FENCE}

That is all." 0

check_write 'a tilde-fenced block is allowed' \
  /r/doc.md "Run it:

${TILDE}sh
grep -rn robust .
${TILDE}" 0

check_write 'an unclosed fence takes the rest of the fragment with it' \
  /r/doc.md "Run it:

${FENCE}sh
grep -rn robust ." 0

check_write 'a banned word after a closed fence is still refused' \
  /r/doc.md "Run it:

${FENCE}sh
echo hi
${FENCE}

This is a robust solution." 2

check_write 'an em dash after a closed fence is still refused' \
  /r/doc.md "Run it:

${FENCE}sh
echo hi
${FENCE}

One${DASH}two." 2

# no content at all
jq -n '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:"/r/doc.md"}}' \
  | bash "$HOOK" >/dev/null 2>&1
if [ $? = 0 ]; then
  pass=$((pass + 1)); printf 'ok    %s\n' 'a payload with no content is ignored'
else
  fail=$((fail + 1)); printf 'FAIL  %s\n' 'a payload with no content is ignored'
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

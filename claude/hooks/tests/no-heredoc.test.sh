#!/usr/bin/env bash
# Tests for hooks/no-heredoc.sh. Run: bash ~/.claude/hooks/tests/no-heredoc.test.sh
#
# Each case feeds the hook a real PreToolUse payload on stdin and asserts the exit code:
# 0 lets the command through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/no-heredoc.sh}"
pass=0
fail=0

check() {
  local name=$1 cmd=$2 want=$3 got
  jq -n --arg cmd "$cmd" \
    '{session_id:"t",transcript_path:"/tmp/t",cwd:"/data/code/pacent",permission_mode:"acceptEdits",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$cmd,description:"d"}}' \
    | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

check 'a heredoc writing a file is refused' \
  "cat > /tmp/s.py <<'PY'
print(1)
PY" 2

check 'a heredoc feeding an interpreter is refused' \
  "python3 - <<'PY'
print(1)
PY" 2

check 'a quote-stripping heredoc is refused' \
  "cat > /tmp/s.txt <<EOF
hello
EOF" 2

check 'a dash-indented heredoc is refused' \
  "cat > /tmp/s.txt <<-EOF
	hello
	EOF" 2

check 'a heredoc after && is refused' \
  "true && cat > /tmp/s.txt <<'EOF'
hello
EOF" 2

check 'a command with no heredoc is allowed' \
  "grep -n foo /data/code/pacent/CLAUDE.md" 0

check 'a herestring is allowed' \
  "grep foo <<< 'foo bar'" 0

check 'the phrase inside single quotes is text, not an invocation' \
  "grep -n 'cat > f <<EOF' /data/code/pacent/docs/shell-and-scripts.md" 0

check 'the phrase inside double quotes is text, not an invocation' \
  "echo \"use cat > f <<EOF to write a file\"" 0

check 'the escape hatch lets a deliberate heredoc through' \
  "cat > /tmp/s.sql <<'SQL' # heredoc-ok
select 1;
SQL" 0

check 'a redirect that is not a heredoc is allowed' \
  "echo hi > /tmp/one.txt" 0

# A run of exactly two `<` was enough on its own, so every left shift was refused.
check 'a left shift in arithmetic expansion is allowed' \
  "echo \$((1<<20))" 0

check 'a spaced left shift in arithmetic expansion is allowed' \
  "echo \$(( 1 << 20 ))" 0

check 'a left shift by a variable is allowed' \
  "bits=4; echo \$((1<<bits))" 0

check 'a left shift in an arithmetic command is allowed' \
  "((x = 1<<20)); echo \$x" 0

check 'a nested left shift in arithmetic is allowed' \
  "echo \$(( (1<<2) + 3 ))" 0

check 'a heredoc after an arithmetic expansion is still refused' \
  "echo \$((1<<20)) && cat > /tmp/s.txt <<'EOF'
hello
EOF" 2

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

#!/usr/bin/env bash
# Tests for hooks/devbox-inline-code.sh. Run: bash ~/.claude/hooks/tests/devbox-inline-code.test.sh
#
# Each case feeds the hook a real PreToolUse payload on stdin and asserts the exit code:
# 0 lets the command through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/devbox-inline-code.sh}"
pass=0
fail=0

check() {
  local name=$1 cmd=$2 want=$3 got
  jq -n --arg cmd "$cmd" \
    '{session_id:"t",transcript_path:"/tmp/t",cwd:"/data/work/zuno",permission_mode:"acceptEdits",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$cmd,description:"d"}}' \
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

DBX='devbox run'

check 'a multi-line devbox call is refused' \
  "$DBX -- bash -c 'echo one
echo two'" 2

check 'a single-line devbox call is allowed' \
  "$DBX -- bash -c 'cd /data/work/zuno/mono/api && bin/rspec'" 0

check 'a command without devbox is ignored' \
  "ls -la /data/work/zuno/mono" 0

check 'a multi-line devbox call after && is refused' \
  "true && $DBX -- bash -c 'echo one
echo two'" 2

check 'the text devbox run inside single quotes is ignored' \
  "grep -n '$DBX' /data/work/zuno/CLAUDE.md" 0

# The case that blocked writing this very test file: a heredoc whose body quotes a devbox
# command. The old substring scan resumed inside the heredoc, met the newline that ends the
# line while still inside the body's double quotes, and called it corrupted inline code.
check 'a devbox call quoted in a heredoc body is ignored' \
  "cat > /tmp/cases.sh <<'EOF'
check 'relative cd is refused' \\
  \"\$WT\" \"$DBX -- bash -c 'cd mono/api && bin/rspec'\" 2
EOF" 0

check 'a devbox call in an unquoted heredoc body is ignored' \
  "cat > /tmp/notes.md <<EOF
$DBX -- bash -c 'echo one
echo two'
EOF" 0

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

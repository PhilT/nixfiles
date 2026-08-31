#!/usr/bin/env bash
# Tests for hooks/devbox-cwd.sh. Run: bash ~/.claude/hooks/tests/devbox-cwd.test.sh
#
# Each case feeds the hook a real PreToolUse payload on stdin and asserts the exit code:
# 0 lets the command through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/devbox-cwd.sh}"
ROOT=/data/work/zuno
WT=/data/work/zuno/worktrees/NA-conventions-registry
MONO=/data/work/zuno/mono
NODEVBOX=$(mktemp -d)

# pacent's shape: devbox.json is tracked in the repo, so the devbox root is the top of the
# working tree and devbox stays put whichever directory the session is in.
INREPO=$(mktemp -d)
git init -q -b main "$INREPO"
: > "$INREPO/devbox.json"
mkdir -p "$INREPO/app/models"

trap 'rm -rf "$NODEVBOX" "$INREPO"' EXIT

pass=0
fail=0

payload() {
  jq -n --arg cwd "$1" --arg cmd "$2" \
    '{session_id:"t",transcript_path:"/tmp/t",cwd:$cwd,permission_mode:"acceptEdits",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$cmd,description:"d"}}'
}

record() {
  local name=$1 want=$2 got=$3
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok    %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL  %s (want exit %s, got %s)\n' "$name" "$want" "$got"
  fi
}

check() {
  local name=$1 cwd=$2 cmd=$3 want=$4
  payload "$cwd" "$cmd" | bash "$HOOK" >/dev/null 2>&1
  record "$name" "$want" "$?"
}

DBX='devbox run'

check 'relative cd from a worktree is refused' \
  "$WT" "$DBX -- bash -c 'cd mono/api && bin/rspec spec/models'" 2

check 'missing cd from a worktree is refused' \
  "$WT" "$DBX -- bash -c 'git commit --amend -F /tmp/msg'" 2

check 'absolute cd from a worktree is allowed' \
  "$WT" "$DBX -- bash -c 'cd $WT/api && bin/rspec spec/models'" 0

check 'bare command from the devbox root is allowed' \
  "$ROOT" "$DBX -- pwd" 0

check 'relative cd from the devbox root is allowed' \
  "$ROOT" "$DBX -- bash -c 'cd mono/api && bin/rspec spec/models'" 0

check 'missing cd from the mono checkout is refused' \
  "$MONO" "$DBX -- bash -c 'bundle exec rubocop'" 2

check 'a command without devbox is ignored' \
  "$WT" "ls -la mono/api" 0

check 'a cd through a variable is refused' \
  "$WT" "$DBX"' -- bash -c '"'"'cd "$HOME/api" && bin/rspec'"'"'' 2

check 'a directory outside any devbox project is allowed' \
  "$NODEVBOX" "$DBX -- bash -c 'bin/rspec'" 0

check 'a second devbox call without a cd is refused' \
  "$WT" "$DBX -- bash -c 'cd $WT/api && a' && $DBX -- bash -c 'b'" 2

check 'git -C with an absolute path is allowed' \
  "$WT" "$DBX -- bash -c 'git -C $WT commit -F /tmp/msg'" 0

check 'a non-git -C absolute path is refused' \
  "$WT" "$DBX -- bash -c 'tar -C /data/work/zuno/mono -cf /tmp/a.tar api'" 2

check 'git -C with a relative path is refused' \
  "$WT" "$DBX -- bash -c 'git -C mono commit -F /tmp/msg'" 2

check 'the text devbox run inside single quotes is ignored' \
  "$WT" "grep -n '$DBX' /data/work/zuno/CLAUDE.md" 0

check 'the text devbox run inside double quotes is ignored' \
  "$WT" "echo \"$DBX -- bash -c 'bin/rspec'\"" 0

check 'the text devbox run in a heredoc body is ignored' \
  "$WT" "cat > /tmp/notes.md <<'EOF'
$DBX -- bash -c 'bin/rspec'
EOF" 0

check 'a real devbox call after && is still checked' \
  "$WT" "true && $DBX -- bash -c 'bin/rspec'" 2

check 'a script file without a cd is refused' \
  "$WT" "$DBX -- bash /tmp/run-specs.sh" 2

check 'a script file behind an absolute cd is allowed' \
  "$WT" "$DBX -- bash -c 'cd $WT && bash /tmp/run-specs.sh'" 0

# Comparing the devbox root against cwd exactly turned every call from a subdirectory into a
# refusal demanding a cd that would change nothing.
check 'a bare command from the top of a repo holding devbox.json is allowed' \
  "$INREPO" "$DBX -- bin/rails test" 0

check 'a bare command from a subdirectory of that repo is allowed' \
  "$INREPO/app" "$DBX -- bin/rails test" 0

check 'a bare command from a deeper subdirectory is allowed' \
  "$INREPO/app/models" "$DBX -- bin/rails test" 0

check 'a bare command from a subdirectory of the mono checkout is still refused' \
  "$MONO/api" "$DBX -- bundle exec rubocop" 2

# The refusal message tells Claude what to write instead. If any command it offers would
# itself be refused, the advice sends Claude round the same loop, so run every example the
# message prints back through the hook and require it to pass.
message=$(payload "$WT" "$DBX -- bash -c 'bin/rspec'" | bash "$HOOK" 2>&1 >/dev/null)
examples=$( { printf '%s\n' "$message" | grep -oE '^  devbox run .*' | sed 's|^  ||'
              printf '%s\n' "$message" | grep -oE '`devbox run [^`]*`' | tr -d '`'
            } | sed 's|<command>|true|' | sort -u)

if [ -z "$examples" ]; then
  fail=$((fail + 1))
  printf 'FAIL  the refusal message prints at least one runnable example\n'
else
  while IFS= read -r example; do
    payload "$WT" "$example" | bash "$HOOK" >/dev/null 2>&1
    record "the message example is accepted: $example" 0 "$?"
  done <<<"$examples"
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
# Cross-cutting contract tests for every PreToolUse hook. Run:
#   bash ~/.claude/hooks/tests/contract.test.sh
#
# The per-hook suites check what each guard decides. These check three things all of them
# owe regardless of what they decide, and which none of them was checking:
#
#   1. A refusal says something. Every per-hook suite asserted the exit code and sent stderr
#      to /dev/null, so a hook that exits 2 with an empty or misleading message passed. For a
#      PreToolUse guard the message is the product: exit 2 stops the call, and the stderr text
#      is the only thing telling Claude what to do instead. A silent refusal reads as an
#      unexplained failure and gets worked around.
#
#   2. Unexpected input does not crash. Claude Code treats any exit code other than 0 or 2 as
#      a non-blocking error and runs the tool anyway, so a hook that dies on a payload shape it
#      did not expect stops guarding without saying so. Empty stdin, valid JSON with no
#      tool_input, and a null command are all shapes a hook can be handed.
#
#   3. A hook returns quickly. These run on every matching tool call, so cost here is paid on
#      every command. The bound is loose on purpose: it is there to catch an order-of-magnitude
#      regression, not to police tens of milliseconds.
set -uo pipefail

HOOKS_DIR="${HOOKS_DIR:-$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)}"
# shellcheck source=lib/assert.sh
. "${BASH_SOURCE[0]%/*}/lib/assert.sh"

pass=0
fail=0
say() {
  if [ "$2" = 0 ]; then pass=$((pass + 1)); printf 'ok    %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL  %s%s\n' "$1" "${3:+ ($3)}"; fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- a fixture that every hook can be pointed at -------------------------------------------
root="$tmp/proj"
mkdir -p "$root/sub"
echo '{}' > "$root/devbox.json"
echo 'AllCops:' > "$root/.rubocop.yml"
git init -q -b main "$root"
git -C "$root" config user.email t@t
git -C "$root" config user.name t
echo x > "$root/a.txt"
git -C "$root" add -A
git -C "$root" commit -qm init
git -C "$root" worktree add -q "$root/wt/mine" -b mine
git -C "$root" worktree add -q "$root/wt/other" -b other
mine="$root/wt/mine"
other="$root/wt/other"

# devbox-cwd refuses only where the devbox root is not the top of the working tree, so its
# fixture puts devbox.json above the repository, which is zuno's shape.
outer="$tmp/outer"
mkdir -p "$outer/repo/sub"
echo '{}' > "$outer/devbox.json"
git init -q -b main "$outer/repo"

# Each row: hook | cwd to run from | payload | expected stderr token.
# The token is a phrase from the refusal that tells the reader what to do differently, so a
# message reduced to "Refused." would fail even though the exit code was still 2.
blocking_case() {
  local name=$1 hook=$2 dir=$3 json=$4 token=$5
  hook_run "$HOOKS_DIR/$hook" "$json" "$dir"
  [ "$HOOK_RC" = 2 ]
  say "$name: refuses with exit 2" $? "got $HOOK_RC"
  [ -n "$HOOK_ERR" ]
  say "$name: the refusal writes to stderr" $?
  assert_says "$token" "$HOOK_ERR"
  say "$name: the message says what to do instead" $? "no '$token' in the message"
}

blocking_case 'block-code-violations' block-code-violations.sh "$root" \
  "$(payload_write "$root/x.rb" 'def a
  # rubocop:disable Metrics/MethodLength
end')" \
  'rubocop:disable'

blocking_case 'prose-rules' prose-rules.sh "$root" \
  "$(payload_write "$root/x.md" 'A sentence — with an em dash.')" \
  'em dash'

blocking_case 'require-worktree' require-worktree.sh "$root" \
  "$(payload_write "$root/x.rb" 'x')" \
  'worktree'

blocking_case 'worktree-containment' worktree-containment.sh "$mine" \
  "$(payload_write "$other/x.rb" 'x')" \
  "$other"

blocking_case 'no-heredoc' no-heredoc.sh "$root" \
  "$(payload_bash 'cat > /tmp/f <<EOF
body
EOF' "$root")" \
  'heredoc'

blocking_case 'devbox-cwd' devbox-cwd.sh "$outer/repo/sub" \
  "$(payload_bash 'devbox run -- bin/rails test' "$outer/repo/sub")" \
  'devbox root'

blocking_case 'devbox-inline-code' devbox-inline-code.sh "$root" \
  "$(payload_bash 'devbox run -- ruby -e "puts 1
puts 2"' "$root")" \
  'multi-line'

blocking_case 'git-shared-branch' git-shared-branch.sh "$mine" \
  "$(payload_bash "git -C $root commit --amend" "$mine")" \
  'shared branch'

# --- unexpected input is survived --------------------------------------------------------
# 0 or 2 only. Anything else is a hook that stopped guarding without saying so.
#
# This is the PreToolUse contract, so it covers only PreToolUse hooks. worktree-create.sh
# answers a different event with the opposite rule: Claude Code aborts creation when the hook
# returns no path, so failing loudly with exit 1 is right there and its own suite checks it.
# hooks-selftest.sh runs this whole suite, so calling it from inside would recurse.
skip_from_pretooluse_contract() {
  case "$1" in
    hooks-selftest.sh|worktree-create.sh|worktree-remove.sh) return 0 ;;
    *) return 1 ;;
  esac
}

malformed_case() {
  local label=$1 json=$2
  for h in "$HOOKS_DIR"/*.sh; do
    [ -e "$h" ] || continue
    local base
    base=$(basename "$h")
    skip_from_pretooluse_contract "$base" && continue
    hook_run "$h" "$json" "$root"
    assert_exit_is_allow_or_block "$HOOK_RC"
    say "$base survives $label" $? "exit $HOOK_RC"
  done
}

malformed_case 'empty stdin' ''
malformed_case 'JSON with no tool_input' '{"session_id":"t","hook_event_name":"PreToolUse"}'
malformed_case 'a null command' \
  '{"session_id":"t","cwd":"/tmp","tool_name":"Bash","tool_input":{"command":null}}'
malformed_case 'a non-object tool_input' \
  '{"session_id":"t","cwd":"/tmp","tool_name":"Bash","tool_input":"oops"}'

# --- speed on a realistic payload ------------------------------------------------------------
# A 500-character command is a normal Bash tool call. Measured, the hooks answer one in 8 to
# 58ms, most of which is starting jq and git rather than any work of their own. The bound is
# 500ms: about ten times the slowest, so a hook that has become an order of magnitude slower
# fails while ordinary variation between machines does not.
long_cmd="devbox run -- bin/rails test $(printf 'test/models/a_test.rb %.0s' $(seq 1 20))"
timing_json=$(payload_bash "$long_cmd" "$root")

for h in "$HOOKS_DIR"/*.sh; do
  [ -e "$h" ] || continue
  base=$(basename "$h")
  # hooks-selftest.sh runs this suite; it is slow by design and cannot time itself.
  [ "$base" = "hooks-selftest.sh" ] && continue
  start=$(date +%s%N)
  hook_run "$h" "$timing_json" "$root"
  end=$(date +%s%N)
  ms=$(( (end - start) / 1000000 ))
  [ "$ms" -lt 500 ]
  say "$base answers a realistic command in under 500ms (${ms}ms)" $?
done

# A long command is where a scanner regression shows first: this took 317ms when the parser
# walked character by character and takes about 18ms now. devbox-scan.test.sh pins the
# library itself; this pins the hook that passes the most through it.
huge=$(printf 'x%.0s' $(seq 1 8000))
start=$(date +%s%N)
hook_run "$HOOKS_DIR/git-shared-branch.sh" "$(payload_bash "git status # $huge" "$root")" "$root"
end=$(date +%s%N)
ms=$(( (end - start) / 1000000 ))
[ "$ms" -lt 400 ]
say "git-shared-branch handles an 8000-character command in under 400ms (${ms}ms)" $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

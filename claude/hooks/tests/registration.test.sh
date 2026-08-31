#!/usr/bin/env bash
# Tests that the hooks are actually wired up. Run:
#   bash ~/.claude/hooks/tests/registration.test.sh
#
# Every other suite runs a hook directly against a payload it builds itself, so all of them
# pass whether or not settings.json still invokes that hook, and none of them can see which
# tools it is invoked for. Both are real gaps: a hook file that drops out of the config keeps
# a green suite while guarding nothing, and the matcher decides which tools reach it at all.
#
# The matcher cases assert the invariant "every tool that can write a file reaches the
# Edit/Write guards". MultiEdit is in the 2.1.247 binary and is not in the matcher, so that
# case fails until settings.json is updated. That is the finding, not a broken test.
set -uo pipefail

SETTINGS="${SETTINGS:-$HOME/.claude/settings.json}"
HOOKS_DIR="${HOOKS_DIR:-$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)}"
pass=0
fail=0

say() {
  if [ "$2" = 0 ]; then pass=$((pass + 1)); printf 'ok    %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; fi
}

command -v jq >/dev/null 2>&1 || { echo "jq required"; exit 1; }
[ -r "$SETTINGS" ] || { echo "no settings at $SETTINGS"; exit 1; }

# Every command string in the hooks config, whatever event or matcher it sits under.
commands=$(jq -r '.hooks | to_entries[] | .value[] | .hooks[]? | .command // empty' "$SETTINGS")

# --- every hook file is registered ------------------------------------------------------
# A hook nobody invokes is dead weight that still passes its own tests.
for h in "$HOOKS_DIR"/*.sh; do
  [ -e "$h" ] || continue
  base=$(basename "$h")
  case "$commands" in
    *"$base"*) say "$base is registered in settings.json" 0 ;;
    *) say "$base is registered in settings.json" 1 ;;
  esac
done

# --- the matcher covers every file-writing tool -------------------------------------------
matcher=$(jq -r '.hooks.PreToolUse[]? | select((.hooks[]?.command // "") | test("require-worktree|worktree-containment|prose-rules|block-code-violations")) | .matcher' "$SETTINGS" | head -1)

for tool in Edit Write NotebookEdit MultiEdit; do
  case "|$matcher|" in
    *"|$tool|"*) say "the Edit/Write matcher covers $tool" 0 ;;
    *) say "the Edit/Write matcher covers $tool" 1 ;;
  esac
done

# --- a NotebookEdit payload is understood by the guards it reaches -------------------------
# The matcher lists NotebookEdit, but NotebookEdit names its target notebook_path rather than
# file_path, so a guard reading only file_path sees no target and allows the write. Only
# worktree-containment.sh is affected: prose-rules is scoped to .md/.erb, block-code-violations
# to .rb, and require-worktree decides from git state without reading a path at all.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo x > "$repo/a.txt"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" worktree add -q "$repo/wt/mine" -b mine
git -C "$repo" worktree add -q "$repo/wt/other" -b other

notebook_into_other=$(jq -n --arg p "$repo/wt/other/x.ipynb" \
  '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"NotebookEdit",
    tool_input:{notebook_path:$p,new_source:"x = 1"}}')

(cd "$repo/wt/mine" && printf '%s' "$notebook_into_other" \
  | bash "$HOOKS_DIR/worktree-containment.sh") >/dev/null 2>&1
[ "$?" = 2 ]
say 'worktree-containment refuses a NotebookEdit into a sibling worktree' $?

notebook_into_own=$(jq -n --arg p "$repo/wt/mine/x.ipynb" \
  '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"NotebookEdit",
    tool_input:{notebook_path:$p,new_source:"x = 1"}}')

(cd "$repo/wt/mine" && printf '%s' "$notebook_into_own" \
  | bash "$HOOKS_DIR/worktree-containment.sh") >/dev/null 2>&1
[ "$?" = 0 ]
say 'worktree-containment allows a NotebookEdit into its own worktree' $?

# require-worktree reads git state, not the payload, so a notebook edit from the main
# checkout is refused for the same reason any other edit is.
(cd "$repo" && printf '%s' "$notebook_into_own" \
  | bash "$HOOKS_DIR/require-worktree.sh") >/dev/null 2>&1
[ "$?" = 2 ]
say 'require-worktree refuses a NotebookEdit from the main checkout' $?

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

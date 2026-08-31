#!/usr/bin/env bash
# SessionStart: run the hook test suite, but only when a deployed hook or test file has
# changed since the last run that passed.
#
# The suite has no other moment to run in. The hooks are built into the system from
# claude/hooks in nixfiles, so a change reaches a session through `nixx build -s`, and
# nothing in that path runs bash tests. Two suites once sat failing for days, one of them
# because worktree-remove.sh was deleting worktrees that held unpushed commits. A session
# start is the first thing that happens after a switch, so that is where this runs.
#
# The checksum guard is what makes it affordable: the suite takes about nine seconds, and it
# runs only in the first session after a switch. A failing run does not record the checksum,
# so it keeps reporting every session until the suite is green again.
#
# It never blocks. Any problem here exits 0 with no output; a broken self-test must not stop a
# session from starting.
set -uo pipefail

root=${BASH_SOURCE[0]%/*}
runner="$root/tests/run-all.sh"
# The hooks themselves are read-only in the nix store, so the state file lives in the cache
# instead. It is machine-local and unsynced, which is what we want: the checksum has to
# describe this machine's deployed hooks, not another machine's.
state="${XDG_CACHE_HOME:-$HOME/.cache}/claude-hooks-selftest"

[ -r "$runner" ] || exit 0
command -v sha256sum >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# One checksum over every hook, library and test file. Sorted, so the order find returns
# them in cannot change the answer.
current=$(
  find "$root" -type f -name '*.sh' -print0 2>/dev/null \
    | sort -z \
    | xargs -0 sha256sum 2>/dev/null \
    | sha256sum \
    | cut -d' ' -f1
)
[ -n "$current" ] || exit 0

previous=$(cat "$state" 2>/dev/null || echo "")
[ "$current" = "$previous" ] && exit 0

output=$(QUIET=1 timeout 120 bash "$runner" 2>&1)
rc=$?

if [ "$rc" = 0 ]; then
  mkdir -p "${state%/*}" 2>/dev/null
  printf '%s\n' "$current" > "$state"
  exit 0
fi

if [ "$rc" = 124 ]; then
  summary="the hook test suite timed out after 120s"
else
  summary=$(printf '%s\n' "$output" | grep -E '^(FAIL|[0-9]+ passed)' | tr '\n' ' ')
fi

jq -n --arg text "[hooks-selftest] A hook file changed and its tests now fail: $summary Run \`bash \$SRC/claude/hooks/tests/run-all.sh\` for the detail, and fix the hook or the test in \$SRC/claude/hooks before relying on either. This will report every session until the suite passes." \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:($text|gsub("  +";" "))}}'
exit 0

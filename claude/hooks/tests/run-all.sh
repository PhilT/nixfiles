#!/usr/bin/env bash
# Run every hook test file and print one total. Exits non-zero if any case failed.
#
#   bash ~/.claude/hooks/tests/run-all.sh          # all suites
#   bash ~/.claude/hooks/tests/run-all.sh worktree # only suites whose name matches
#   QUIET=1 bash ~/.claude/hooks/tests/run-all.sh  # per-suite lines only for failures
#
# Without this the suites could only be run one at a time, so "the tests exist" and "the hooks
# work" were unrelated facts: two suites sat failing and nothing said so. hooks-selftest.sh
# runs this on SessionStart when a hook file has changed.
set -uo pipefail

dir=${BASH_SOURCE[0]%/*}
filter=${1:-}
quiet=${QUIET:-0}

total_pass=0
total_fail=0
failed_suites=()

for t in "$dir"/*.test.sh; do
  [ -e "$t" ] || continue
  name=$(basename "$t" .test.sh)
  case "$name" in
    *"$filter"*) ;;
    *) continue ;;
  esac

  out=$(bash "$t" 2>&1)
  rc=$?
  # Every suite ends with "<n> passed, <n> failed".
  tally=$(printf '%s\n' "$out" | grep -E '^[0-9]+ passed, [0-9]+ failed$' | tail -1)
  p=${tally%% *}
  f=${tally##*, }
  f=${f%% *}
  [ -n "$p" ] || p=0
  [ -n "$f" ] || f=0
  total_pass=$((total_pass + p))
  total_fail=$((total_fail + f))

  if [ "$rc" = 0 ] && [ "$f" = 0 ]; then
    [ "$quiet" = 1 ] || printf 'ok    %-28s %s passed\n' "$name" "$p"
  else
    failed_suites+=("$name")
    printf 'FAIL  %-28s %s passed, %s failed\n' "$name" "$p" "$f"
    printf '%s\n' "$out" | grep -E '^FAIL' | sed 's/^/        /'
  fi
done

printf '\n%s passed, %s failed' "$total_pass" "$total_fail"
if [ "${#failed_suites[@]}" -gt 0 ]; then
  printf ' (%s)' "${failed_suites[*]}"
fi
printf '\n'
[ "$total_fail" = 0 ] && [ "${#failed_suites[@]}" = 0 ]

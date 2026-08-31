#!/usr/bin/env bash
# Tests for hooks/block-code-violations.sh. Run:
#   bash ~/.claude/hooks/tests/block-code-violations.test.sh
#
# The hook decides from the target path, so the test builds four trees: a repo with a linted
# subtree (api/.rubocop.yml), a no-new-comments marker and a worktree; a repo linted at its root
# whose marker sits one directory above it (zuno's shape); a repo linted at its root with no
# marker anywhere; and a repo with no rubocop config at all. 0 lets the edit through, 2 blocks it
# and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/block-code-violations.sh}"
pass=0
fail=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
mkdir -p "$repo/api" "$repo/tools" "$repo/.claude"
git init -q -b main "$repo"
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo 'AllCops:' > "$repo/api/.rubocop.yml"
echo hello > "$repo/tools/README.md"
touch "$repo/.claude/no-new-comments"
git -C "$repo" add -A
git -C "$repo" commit -qm init
git -C "$repo" worktree add -q "$repo/worktrees/mine" -b mine

# zuno's shape: the marker sits above the repository, not inside it.
above="$tmp/above"
mkdir -p "$above/mono" "$above/.claude"
git init -q -b main "$above/mono"
echo 'AllCops:' > "$above/mono/.rubocop.yml"
touch "$above/.claude/no-new-comments"

# Linted, but has not opted in to the comment rule.
lenient="$tmp/lenient"
mkdir -p "$lenient"
git init -q -b main "$lenient"
echo 'AllCops:' > "$lenient/.rubocop.yml"

# Linted in one subtree only, with no marker, so rule 1's reach can be seen on its own.
partly="$tmp/partly"
mkdir -p "$partly/api" "$partly/tools"
git init -q -b main "$partly"
echo 'AllCops:' > "$partly/api/.rubocop.yml"

plain="$tmp/plain"
mkdir -p "$plain"
git init -q -b main "$plain"

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

check_write 'a new comment where the repo opted in is refused' \
  "$repo/api/thing.rb" '# explains the thing
puts 1' 2

check_edit 'a new comment added by Edit is refused' \
  "$repo/api/thing.rb" '# explains the thing
puts 1' 2

check_write 'an indented comment is refused' \
  "$repo/api/thing.rb" 'def go
  # why we do this
  1
end' 2

check_write 'a magic comment is allowed' \
  "$repo/api/thing.rb" '# frozen_string_literal: true

puts 1' 0

check_write 'a TODO marker is allowed' \
  "$repo/api/thing.rb" '# TODO: drop this once APY-1 lands
puts 1' 0

check_write 'a rubocop:enable is allowed' \
  "$repo/api/thing.rb" '# rubocop:enable Metrics/AbcSize
puts 1' 0

check_write 'ruby with no comment is allowed' \
  "$repo/api/thing.rb" 'def go
  1
end' 0

check_write 'a hash inside a string is not a comment' \
  "$repo/api/thing.rb" 'puts "# not a comment"' 0

# The regression this hook was made global to fix: every zuno edit happens in a worktree.
check_write 'a new comment in a worktree of the opted-in repo is refused' \
  "$repo/worktrees/mine/api/thing.rb" '# explains the thing
puts 1' 2

check_write 'a file whose directory does not exist yet is still judged' \
  "$repo/api/app/models/thing.rb" '# explains the thing
puts 1' 2

# Rule 2 asks the repo, not rubocop, so it reaches the whole repository once the marker is
# there. Rule 1 is the one bounded by where a .rubocop.yml sits.
check_write 'a comment outside the linted subtree is refused where the repo opted in' \
  "$repo/tools/thing.rb" '# explains the thing
puts 1' 2

check_write 'a rubocop:disable outside the linted subtree is allowed' \
  "$partly/tools/thing.rb" '# rubocop:disable Metrics/AbcSize
puts 1' 0

check_write 'a rubocop:disable inside the linted subtree is refused' \
  "$partly/api/thing.rb" '# rubocop:disable Metrics/AbcSize
puts 1' 2

check_write 'a marker one directory above the repo opts it in' \
  "$above/mono/thing.rb" '# explains the thing
puts 1' 2

# The split: rule 1 is global, rule 2 is opt-in. These two paths differ only in the marker.
check_write 'a comment in a linted repo with no marker is allowed' \
  "$lenient/thing.rb" '# explains the thing
puts 1' 0

check_write 'a rubocop:disable in a linted repo with no marker is still refused' \
  "$lenient/thing.rb" '# rubocop:disable Metrics/AbcSize
puts 1' 2

check_write 'a rubocop:disable where the repo opted in is refused' \
  "$repo/api/thing.rb" '# rubocop:disable Metrics/AbcSize
puts 1' 2

check_write 'a rubocop:disable in a repo with no rubocop config is allowed' \
  "$plain/thing.rb" '# rubocop:disable Metrics/AbcSize
puts 1' 0

check_write 'a comment in a repo with no rubocop config is allowed' \
  "$plain/thing.rb" '# explains the thing
puts 1' 0

check_write 'ruby outside any repository is allowed' \
  "$tmp/thing.rb" '# explains the thing
puts 1' 0

check_write 'a comment in a non-ruby file is allowed' \
  "$repo/api/thing.py" '# explains the thing
print(1)' 0

# rubocop lints .rake and Rakefile too, and reads the directive with or without the space
# after the hash, and `todo` the same way as `disable`.
check_write 'a rubocop:disable in a rake task is refused' \
  "$lenient/thing.rake" '# rubocop:disable Metrics/AbcSize
task :go' 2

check_write 'a rubocop:disable in a Rakefile is refused' \
  "$lenient/Rakefile" '# rubocop:disable Metrics/AbcSize
task :go' 2

check_write 'a rubocop:disable with no space after the hash is refused' \
  "$lenient/thing.rb" '#rubocop:disable Metrics/AbcSize
puts 1' 2

check_write 'a rubocop:todo is refused' \
  "$lenient/thing.rb" '# rubocop:todo Metrics/AbcSize
puts 1' 2

check_write 'a comment in a rake task where the repo opted in is refused' \
  "$repo/api/thing.rake" '# explains the thing
task :go' 2

jq -n --arg p "$repo/api/thing.rb" \
  '{hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p}}' \
  | bash "$HOOK" >/dev/null 2>&1
if [ $? = 0 ]; then
  pass=$((pass + 1)); printf 'ok    %s\n' 'a payload with no content is ignored'
else
  fail=$((fail + 1)); printf 'FAIL  %s\n' 'a payload with no content is ignored'
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]

#!/usr/bin/env bash
# PreToolUse (Bash): refuse a `devbox run` that would silently execute somewhere other than
# the directory this session is working in.
#
# `devbox run` does not inherit the shell's cwd. It runs the command at the devbox project
# root: the nearest ancestor of cwd holding devbox.json. In zuno that root is
# /data/work/zuno, which sits *above* the git repo (/data/work/zuno/mono), so no worktree
# ever contains a devbox.json of its own and every `devbox run` from a worktree lands in the
# shared checkout sitting on main. On 2026-08-07 that turned two `git commit --amend` calls
# into a rewrite of a colleague's commit at the tip of main. The harness worktree guard
# blocks `-C` and a `cd` into the shared checkout, but it cannot see past the devbox wrapper.
#
# Where devbox.json is tracked in the repo (pacent), each worktree has its own and devbox
# stays put, so this hook finds the devbox root is the worktree itself and allows everything,
# from any directory under it.
#
# The rule: once cwd is not the devbox root, the command must say where it runs, with a
# literal absolute `cd`, or an absolute `git -C`. A relative path, a path through a variable,
# and no path at all are refused: each resolves against the root rather than against cwd.
#
# Only a real invocation counts. `devbox run` inside quotes or a heredoc body is text being
# searched for or written to a file, not a command, so grepping for the phrase and writing
# docs about it are left alone; a guard that fires on its own name gets worked around.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

lib="${BASH_SOURCE[0]%/*}/lib/devbox-scan.sh"
[ -r "$lib" ] || exit 0
# shellcheck source=lib/devbox-scan.sh
. "$lib"

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
[ -n "$cwd" ] || exit 0
case "$cmd" in *devbox*) ;; *) exit 0 ;; esac

root=""
dir=$cwd
while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -f "$dir/devbox.json" ]; then
    root=$dir
    break
  fi
  dir=$(dirname "$dir")
done

[ -n "$root" ] || exit 0

# The risk is the command landing in a different checkout, so the comparison is against the
# top of the working tree, not against cwd. Where devbox.json is tracked in the repo the root
# is that top, and the command runs on the right branch from any directory under it; testing
# cwd exactly turned every call from a subdirectory into a refusal demanding a cd that would
# change nothing.
cwd_r=$(cd "$cwd" 2>/dev/null && pwd -P) || cwd_r=$cwd
root_r=$(cd "$root" 2>/dev/null && pwd -P) || root_r=$root
top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) && top=$(cd "$top" && pwd -P) || top=""

[ "$root_r" = "$cwd_r" ] && exit 0
[ -n "$top" ] && [ "$root_r" = "$top" ] && exit 0


while IFS= read -r offset; do
  [ -n "$offset" ] || continue
  rest=${cmd:offset}
  rest=${rest#*run}
  if ! devbox_segment "$rest" | grep -qE "(^|[[:space:]]|[\"'])cd[[:space:]]+/|git[[:space:]]+-C[[:space:]]+/"; then
    cat >&2 <<MSG
Refused: this \`devbox run\` has no literal absolute \`cd\`, so it will not run where you think.

  session cwd:  $cwd
  devbox root:  $root   <- the command would run here

devbox run ignores the shell's cwd and executes at the devbox project root. From this
directory that means the command lands in $root instead of $cwd.
A relative \`cd\` resolves against the root too, so it misses in the same way, and a \`cd\`
through a variable cannot be checked.

Name the directory in full:
  devbox run -- bash -c 'cd $cwd && <command>'

Git is the dangerous case: without the cd, a commit, amend or rebase applies to whatever
branch the root checkout has out, not to your branch. For a single git command, put the path
inside the invocation so there is no separate cd line to lose:
  devbox run -- bash -c 'git -C $cwd commit -F /path/to/message'

For anything longer than one command, put the body in a script file and keep the cd on the
outside, so it cannot go missing while the command is being composed:
  devbox run -- bash -c 'cd $cwd && bash /path/to/script.sh'
MSG
    exit 2
  fi
done < <(devbox_invocations "$cmd")
exit 0

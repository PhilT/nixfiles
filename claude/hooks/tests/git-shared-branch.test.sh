#!/usr/bin/env bash
# Tests for hooks/git-shared-branch.sh. Run: bash ~/.claude/hooks/tests/git-shared-branch.test.sh
#
# Each case feeds the hook a real PreToolUse payload on stdin and asserts the exit code:
# 0 lets the command through, 2 blocks it and shows stderr to Claude.
set -uo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/git-shared-branch.sh}"
MONO=/data/work/zuno/mono
ROOT=/data/work/zuno
WT=/data/work/zuno/worktrees/NA-conventions-registry
pass=0
fail=0

check() {
  local name=$1 cwd=$2 cmd=$3 want=$4 got
  jq -n --arg cwd "$cwd" --arg cmd "$cmd" \
    '{session_id:"t",transcript_path:"/tmp/t",cwd:$cwd,permission_mode:"acceptEdits",hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$cmd,description:"d"}}' \
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

check 'amend with cwd on main is refused' \
  "$MONO" "git commit --amend --no-edit" 2

# /data/work/zuno holds a gitfile pointing at mono/.git, so git run there is git run on main.
check 'amend from the devbox root is refused' \
  "$ROOT" "git commit --amend --no-edit" 2

check 'amend in a worktree on a feature branch is allowed' \
  "$WT" "git commit --amend --no-edit" 0

check 'amend behind an explicit cd to the shared checkout is refused' \
  "$WT" "devbox run -- bash -c 'cd $MONO && git commit --amend -F /tmp/msg'" 2

check 'amend through git -C to the shared checkout is refused' \
  "$WT" "devbox run -- bash -c 'git -C $MONO commit --amend -F /tmp/msg'" 2

check 'amend behind an explicit cd to a worktree is allowed' \
  "$WT" "devbox run -- bash -c 'cd $WT && git commit --amend -F /tmp/msg'" 0

check 'rebase with cwd on main is refused' \
  "$MONO" "git rebase -i HEAD~2" 2

check 'reset --hard with cwd on main is refused' \
  "$MONO" "git reset --hard origin/main" 2

check 'a force push naming main is refused' \
  "$WT" "git push --force origin main" 2

check 'force-with-lease on a feature branch is allowed' \
  "$WT" "git push --force-with-lease origin NA-conventions-registry" 0

check 'a plain commit on main is allowed' \
  "$MONO" "git commit -m 'wip'" 0

check 'a read-only git command on main is allowed' \
  "$MONO" "git status --short" 0

# The phrase written as text is not a command. A guard that fires on its own name gets
# worked around, and the devbox root resolves to main, where Phil greps and echoes all day.
check 'the phrase echoed on main is ignored' \
  "$ROOT" "echo \"git commit --amend\"" 0

check 'the phrase grepped on main is ignored' \
  "$ROOT" "grep -rn 'commit --amend' /data/work/zuno/CLAUDE.md" 0

check 'the phrase in a heredoc body on main is ignored' \
  "$ROOT" "cat > /tmp/notes.md <<'EOF'
git commit --amend --no-edit
git rebase -i HEAD~2
EOF" 0

check 'a non-git command on main is ignored' \
  "$MONO" "ls -la" 0

# --force is a rewrite only on push. These subcommands take it for unrelated reasons and must
# pass even with the shared checkout on main.
check 'worktree remove --force on main is allowed' \
  "$MONO" "git worktree remove --force /data/work/zuno/worktrees/gone" 0

check 'worktree add --force on main is allowed' \
  "$MONO" "git worktree add --force /tmp/wt some-branch" 0

check 'checkout --force on main is allowed' \
  "$MONO" "git checkout --force some-branch" 0

check 'switch --force on main is allowed' \
  "$MONO" "git switch --force some-branch" 0

check 'clean -f on main is allowed' \
  "$MONO" "git clean -f -d" 0

check 'branch --force on main is allowed' \
  "$MONO" "git branch --force some-branch HEAD" 0

check 'tag --force on main is allowed' \
  "$MONO" "git tag --force v1.0" 0

check 'rm --force on main is allowed' \
  "$MONO" "git rm --force some-file.txt" 0

check 'submodule update --force on main is allowed' \
  "$MONO" "git submodule update --force" 0

check 'a bare force push from main is still refused' \
  "$MONO" "git push --force" 2

check 'force-with-lease from main is still refused' \
  "$MONO" "git push --force-with-lease origin HEAD" 2

# git reached through a wrapper. Matching only a first word of literally `git` let every one
# of these through, and `devbox run --` is the shape CLAUDE.md tells each session to use.
check 'amend through devbox run is refused' \
  "$MONO" "devbox run -- git commit --amend --no-edit" 2

check 'amend through sudo is refused' \
  "$MONO" "sudo git commit --amend --no-edit" 2

check 'amend behind an environment assignment is refused' \
  "$MONO" "GIT_AUTHOR_NAME=x git commit --amend --no-edit" 2

check 'amend through env is refused' \
  "$MONO" "env GIT_AUTHOR_NAME=x git commit --amend --no-edit" 2

check 'amend through an absolute git path is refused' \
  "$MONO" "/run/current-system/sw/bin/git commit --amend --no-edit" 2

check 'amend through devbox run in a worktree is allowed' \
  "$WT" "devbox run -- git commit --amend --no-edit" 0

# A wrapped command that merely has a path ending in git is not a git invocation.
check 'a wrapped non-git command is ignored' \
  "$MONO" "devbox run -- ls -la /data/code/git" 0

# Relative directories. Both forms used to be dropped, leaving the branch read from the
# session's own checkout: the amend below was allowed, and the last case was refused.
check 'amend through a relative git -C to the shared checkout is refused' \
  "$WT" "git -C ../../mono commit --amend --no-edit" 2

check 'amend behind a relative cd to the shared checkout is refused' \
  "$WT" "cd ../../mono && git commit --amend --no-edit" 2

check 'amend through a relative git -C to a worktree is allowed' \
  "$MONO" "git -C ../worktrees/NA-conventions-registry commit --amend --no-edit" 0

# The subcommand decides what is a rewrite. `rebase` matched anywhere refused the standard
# way out of a conflict, and a read.
check 'rebase --abort on main is allowed' \
  "$MONO" "git rebase --abort" 0

check 'rebase --continue on main is allowed' \
  "$MONO" "git rebase --continue" 0

check 'rebase --skip on main is allowed' \
  "$MONO" "git rebase --skip" 0

check 'log --grep rebase on main is allowed' \
  "$MONO" "git log --grep rebase --oneline" 0

check 'a plain rebase on main is still refused' \
  "$MONO" "git rebase origin/main" 2

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

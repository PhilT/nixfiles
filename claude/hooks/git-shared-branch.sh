#!/usr/bin/env bash
# PreToolUse (Bash): refuse a git command that would rewrite history on a shared branch.
#
# On 2026-08-07 a `git commit --amend` meant for a feature branch ran against the tip of
# main and rewrote a colleague's commit, recovered by hand from mono/.git/logs/HEAD.
# devbox-cwd.sh now stops the version of that mistake where the directory goes unstated, but
# a command can still name the shared checkout outright, and `/data/work/zuno` itself holds
# a gitfile pointing at mono/.git, so plain git run from the devbox root is git run on main.
#
# The check is on the target, not on the session: work out which checkout the command would
# act on (an explicit `git -C`, else a `cd` earlier in the same chain, else the session cwd),
# ask that checkout what branch it has out, and refuse only when the answer is a shared one.
# A force push is also refused when its refspec names a shared branch, whatever the checkout.
#
# Finding git in the segment takes more than reading the first word. `devbox run -- git commit
# --amend` is the exact shape of the incident above, and `sudo git`, `env X=1 git` and
# `/run/current-system/sw/bin/git` all run git too, so the scan steps over environment
# assignments and a fixed list of command wrappers, and matches the last path segment of the
# word. It stops at a quote, because a quoted body is walked separately as its own command,
# and stops at any other command name, so `grep 'git commit --amend'` is left alone.
#
# What counts as a rewrite is decided from git's subcommand, not from the flags appearing
# anywhere in the line. `git rebase --abort` is the standard way out of a conflict and
# `git log --grep rebase` reads; matching the word `rebase` refused both. Equally `--force`
# is a rewrite only on push: `git worktree remove --force` and `git checkout --force` are not.
#
# Directories are resolved against the directory the command would run in, so a relative
# `git -C ../main` or `cd ../main` names the checkout it actually reaches rather than being
# read as the session's own.
#
# Only a real invocation counts. The phrase written as text (echoed, grepped, or sitting in a
# heredoc body) is left alone: the devbox root resolves to main, so a guard that fired on its
# own name would trip on ordinary reading and get worked around.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

lib="${BASH_SOURCE[0]%/*}/lib/devbox-scan.sh"
[ -r "$lib" ] || exit 0
# shellcheck source=lib/devbox-scan.sh
. "$lib"

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
[ -n "$cwd" ] || exit 0
case "$cmd" in *git*) ;; *) exit 0 ;; esac

SHARED='main|master|develop'

# Commands that run another command as their argument. Stepping over these and their own
# options is what lets `devbox run -- git …` and `sudo git …` be seen as git.
WRAPPERS='sudo|doas|env|command|exec|nice|ionice|nohup|time|stdbuf|timeout|setsid|xargs|devbox|direnv|flock'

# Shells take their command as a quoted argument instead, so the wrapper scan stops here and
# shell_dash_c_body walks that body as commands in its own right.
SHELLS='bash|sh|dash|zsh|ksh|fish'

refuse() {
  local what=$1 where=$2 branch=$3
  cat >&2 <<MSG
Refused: this command rewrites history on a shared branch.

  command:  $what
  checkout: $where
  branch:   $branch

That checkout has a shared branch out, so an amend, rebase, reset --hard or force push
there rewrites commits other people already have. On 2026-08-07 exactly this rewrote a
colleague's commit at the tip of main and had to be recovered from mono/.git/logs/HEAD.

If you meant your own branch, name its checkout: \`git -C /path/to/worktree …\`, or \`cd\`
there first. If you really do mean the shared branch, run it yourself outside Claude Code.
MSG
  exit 2
}

branch_of() {
  git -C "$1" branch --show-current 2>/dev/null
}

# resolve_dir <path> <base>: the directory <path> names when the command runs in <base>.
resolve_dir() {
  local p=$1 base=$2
  p=${p#\"}; p=${p%\"}
  p=${p#\'}; p=${p%\'}
  case "$p" in
    "~")   p=$HOME ;;
    "~/"*) p=$HOME/${p#\~/} ;;
  esac
  case "$p" in
    /*) readlink -m "$p" ;;
    *)  readlink -m "$base/$p" ;;
  esac
}

# git_word_index: echo the index of the word that runs git in the words array, or nothing.
git_word_index() {
  local i w base wrapped=0
  for i in "${!words[@]}"; do
    w=${words[i]}
    case "$w" in *\'*|*\"*) return ;; esac      # a quoted body: walked separately
    base=${w##*/}
    if [ "$base" = git ]; then printf '%s' "$i"; return; fi
    case "$w" in [A-Za-z_]*=*) continue ;; esac # environment assignment prefix
    [[ $base =~ ^($SHELLS)$ ]] && return
    if [[ $base =~ ^($WRAPPERS)$ ]]; then wrapped=1; continue; fi
    [ "$wrapped" = 1 ] && continue              # the wrapper's own subcommand, options or --
    return                                      # some other command entirely
  done
}

has_arg() {                                     # has_arg <word> against the args array
  local want=$1 a
  for a in "${args[@]}"; do
    [ "$a" = "$want" ] && return 0
  done
  return 1
}

# A push is forced by any of these, including the `=` form of --force-with-lease.
push_is_forced() {
  local a
  for a in "${args[@]}"; do
    case "$a" in
      --force|--force-with-lease|--force-with-lease=*|--force-if-includes|-f) return 0 ;;
    esac
  done
  return 1
}

# A refspec names a shared branch when its destination does: `main`, `feature:main` and
# `+refs/heads/main` all push to main, while `main-thing` and `origin` do not.
push_names_shared() {
  local a dst
  for a in "${args[@]}"; do
    case "$a" in -*) continue ;; esac
    dst=${a#+}
    dst=${dst##*:}
    dst=${dst##*/}
    [[ $dst =~ ^($SHARED)$ ]] && return 0
  done
  return 1
}

inspect() {
  local body=$1 target=$2
  local seg word gi j w dir sub branch nested
  local -a words args

  while IFS= read -r -d '' seg; do
    words=()
    IFS=$' \t\n' read -r -d '' -a words < <(printf '%s' "$seg")
    [ "${#words[@]}" -gt 0 ] || continue

    word=${words[0]}
    if [ "$word" = cd ]; then
      # `cd` with no argument, or `cd -`, goes somewhere this cannot follow, so the target is
      # left as it was rather than guessed at.
      w=${words[1]:-}
      case "$w" in ""|-) ;; *) target=$(resolve_dir "$w" "$target") ;; esac
      continue
    fi

    gi=$(git_word_index)
    if [ -z "$gi" ]; then
      nested=$(shell_dash_c_body "$seg")
      [ -n "$nested" ] && inspect "$nested" "$target"
      continue
    fi

    # Step over git's own options to reach the subcommand, taking the directory from -C.
    dir=$target
    j=$((gi + 1))
    while [ "$j" -lt "${#words[@]}" ]; do
      w=${words[j]}
      case "$w" in
        -C)  [ -n "${words[j+1]:-}" ] && dir=$(resolve_dir "${words[j+1]}" "$target")
             j=$((j + 2)) ;;
        -C*) dir=$(resolve_dir "${w#-C}" "$target"); j=$((j + 1)) ;;
        -c)  j=$((j + 2)) ;;
        -*)  j=$((j + 1)) ;;
        *)   break ;;
      esac
    done

    sub=${words[j]:-}
    [ -n "$sub" ] || continue
    args=("${words[@]:j+1}")

    case "$sub" in
      commit)        has_arg --amend || continue ;;
      reset)         has_arg --hard  || continue ;;
      filter-branch) ;;
      rebase)
        has_arg --abort && continue
        has_arg --continue && continue
        has_arg --skip && continue
        has_arg --quit && continue ;;
      push)
        push_is_forced || continue
        if push_names_shared; then
          refuse "$seg" "$dir (refspec)" "named in the push"
        fi ;;
      *) continue ;;
    esac

    branch=$(branch_of "$dir")
    [ -n "$branch" ] || continue
    if [[ $branch =~ ^($SHARED)$ ]]; then
      refuse "$seg" "$dir" "$branch"
    fi
  done < <(shell_segments "$body")
}

inspect "$cmd" "$cwd"
exit 0

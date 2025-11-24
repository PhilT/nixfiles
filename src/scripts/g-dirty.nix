{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "g-dirty" ''
      OPT_BOLD="-b"
      OPT_CD="-s"
      OPT_HELP="--help"

      opts=$1

      if [ "$opts" = "$OPT_HELP" ]; then
        echo "Usage: g-dirty [$OPT_CD] [$OPT_BOLD]"
        echo "  $OPT_CD Return the first dirty repo to facilite cleaning"
        echo "  $OPT_BOLD Highlight first dirty repo to facilite cleaning"
        exit
      fi

      [ "$opts" = "$OPT_CD" ] || echo "Changes in $CODE projects:"

      if [ -z "$CODE" ]; then
        echo "ERROR: \$CODE environment variable not set"
        exit 1
      fi

      # Ignore list - repositories to skip
      ignore_list=("nixfiles-clone")
      normal='\033[0m'
      first_repo=""

      for dir in "$CODE"/*; do
        if [ -d "$dir/.git" ]; then
          cd "$dir" || continue
          repo_name=$(basename "$dir")

          # Skip if in ignore list
          if [[ " ''${ignore_list[@]} " =~ " ''${repo_name} " ]]; then
            continue
          fi

          branches=()

          # Check for uncommitted changes (modified, staged, or untracked files)
          if ! git diff-index --quiet HEAD -- 2>/dev/null || \
             [ -n "$(git ls-files --others --exclude-standard)" ]; then
            branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            [ -n "$branch" ] && branches+=("$branch")
          fi

          # Check for branches with unpushed commits or no remote
          while IFS= read -r line; do
            local_branch=$(echo "$line" | awk '{print $1}')
            upstream_branch=$(echo "$line" | awk '{print $2}')

            if [ -z "$upstream_branch" ]; then
              # Branch has no remote
              [[ ! " ''${branches[@]} " =~ " ''${local_branch} " ]] && branches+=("$local_branch")
            else
              # Check for unpushed commits
              unpushed=$(git rev-list "$upstream_branch..$local_branch" --count 2>/dev/null)
              if [ "$unpushed" -gt 0 ]; then
                [[ ! " ''${branches[@]} " =~ " ''${local_branch} " ]] && branches+=("$local_branch")
              fi
            fi
          done < <(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads)

          # Output repo and branches if any issues found
          if [ ''${#branches[@]} -gt 0 ]; then
            if [ "$opts" = "$OPT_BOLD" ]; then
              bold='\033[1m'
            else
              bold='\033[0m'
            fi

            [ "$opts" = "$OPT_CD" ] || echo -e "| $bold$repo_name: ''${branches[*]}$normal"
            bold=$normal
            [ -z "$first_repo" ] && first_repo=$repo_name
          fi
        fi
      done

      if [ "$opts" = "$OPT_CD" ]; then
        echo "$first_repo"
      elif [ "$first_repo" = "" ]; then
        echo "All projects are clean!"
      fi
    '')
  ];
}
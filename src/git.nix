{ config, pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "g-cd" ''
      [ -d "$CODE/$PROJ" ] || git clone git@github.com:PhilT/$PROJ.git $CODE/$PROJ
      cd "$CODE/$PROJ"
    '')

    (writeShellScriptBin "g-dirty" ''
      if [ -z "$CODE" ]; then
        echo "ERROR: \$CODE environment variable not set"
        exit 1
      fi

      # Ignore list - repositories to skip
      ignore_list=("nixfiles-clone")
      found_issues=false

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
            echo "$repo_name: ''${branches[*]}"
            found_issues=true
          fi
        fi
      done

      if [ "$found_issues" = false ]; then
        echo "Everything is clean!"
      fi
    '')
  ];

  environment.shellAliases = {
    matter = "PROJ=matter source /run/current-system/sw/bin/g-cd";
    cv_builder = "PROJ=cv_builder source /run/current-system/sw/bin/g-cd";
    vim-fsharp = "PROJ=vim-fsharp source /run/current-system/sw/bin/g-cd";
    sheetzi = "PROJ=sheetzi source /run/current-system/sw/bin/g-cd";
    rails_bootstrap = "PROJ=rails_bootstrap source /run/current-system/sw/bin/g-cd";
  };

  environment.etc = {
    "gitconfig-personal" = {
      mode = "444";
      text = ''
        [user]
          name = "${config.fullname}"
          email = "34678+PhilT@users.noreply.github.com"
      '';
    };
  };

  programs.git.config = {
    apply.whitespace = "nowarn";
    branch.autosetupmerge = "true";
    branch.autosetuprebase = "always";
    color.ui = "true";
    diff.wsErrorHighlight = "all";
    init.defaultBranch = "main";
    merge.tool = "vimdiff";
    mergetool.path = "nvim";
    pull.rebase = "true";
    push.autoSetupRemote = "true";
    push.default = "current";

    github.user = "PhilT";

    "includeIf \"gitdir:/data/code/\"" = {
      path = "/etc/gitconfig-personal";
    };

    alias = {
      ap = "!git add -N . && git add -p";
      cf = "clean -fd --exclude=.scratch.txt";
      ss = "stash";
      sd = "stash -- $\\\\(git diff --staged --name-only\\\\)";
      pp = "stash pop";
      cl = "branch -d $(git branch --merged | grep -v '\\\\(\\\\*\\\\|develop\\\\|master\\\\)')";
      st = "status -s";
      ci = "commit";
      br = "branch";
      co = "checkout";
      df = "diff HEAD -w";
      ds = "diff --staged";
      lg = "log -p";
      lo = "log --oneline --no-merges";
      lf = "log --name-only --oneline";
      lfd = "log --name-only --oneline --diff-filter=ACMRTUXB";
      pf = "push --force-with-lease";
      rem = "!git fetch && git rebase origin/master";
      pm = "!git co master && git pull";
      rc = "rebase --continue";
      ra = "rebase --abort";
      rs = "rebase --skip";
      ri = "rebase -i";
      cc = "cherry-pick --continue";
      ca = "cherry-pick --abort";
      cs = "cherry-pick --skip";
      x = "update-index --chmod=+x";
    };

    core = {
      whitespace = "-trailing-space";
      excludesfile = "/etc/gitignore";
      autocrlf = "false";
      eol = "lf";
      editor = "nvim";
    };
  };
}
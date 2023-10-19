{ config, pkgs, ... }:

{
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

    user = {
      name = "Phil Thompson";
      email = "34678+PhilT@users.noreply.github.com";
    };
    github.user = "PhilT";

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
      df = "diff HEAD";
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

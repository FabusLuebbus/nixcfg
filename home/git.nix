{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      # ---- EDIT THESE ----
      user.name = "Fabian Luebbe";
      user.email = "fabian.luebbe@gmail.com";
      # --------------------

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      diff.algorithm = "histogram";
      rerere.enabled = true;

      # Commit signing — uncomment once your key is in place.
      # user.signingkey = "CHANGEME";
      # commit.gpgsign = true;

      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        lg = "log --oneline --graph --decorate --all";
        last = "log -1 HEAD --stat";
        unstage = "reset HEAD --";
        amend = "commit --amend --no-edit";
      };
    };

    ignores = [
      "*.swp"
      ".DS_Store"
      ".direnv/"
      ".venv/"
      "__pycache__/"
      ".ruff_cache/"
      ".ipynb_checkpoints/"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.lazygit.enable = true;
}

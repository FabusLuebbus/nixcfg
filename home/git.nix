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
        last = "log -1 HEAD --stat";
        unstage = "reset HEAD --";
        amend = "commit --amend --no-edit";

        lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
        lg = "lg1";
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

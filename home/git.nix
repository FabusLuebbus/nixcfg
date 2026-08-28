{
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      # ---- EDIT THESE ----
      user.name = "Fabian Luebbe";
      user.email = "fabian.luebbe@gmail.com";
      # --------------------

      core.editor = "nvim";
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

    # delta's git integration below also claims pager.log via iniContent,
    # but delta expects diff hunks -- a plain `--graph` log (no -p) has
    # none, and feeding it one leaves delta sitting at its `less` prompt
    # looking stuck. Keep delta for diff/show/blame; log gets a plain
    # pager. This must override `iniContent` directly (not `settings`,
    # which is copied into `iniContent` as a plain value and would lose
    # the mkForce) since delta.nix sets iniContent.pager.log too.
    iniContent.pager.log = lib.mkForce "less -FRX";

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

  # Colors ported verbatim from catppuccin/delta's mocha config
  # (https://github.com/catppuccin/delta) rather than the bat-bundled
  # "Catppuccin Mocha" syntax-theme alone, since that only recolors code
  # tokens inside a hunk -- these keys are what themes the diff chrome
  # (line numbers, +/- backgrounds, headers) around it.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;

      syntax-theme = "Catppuccin Mocha";
      dark = true;
      file-style = "#cdd6f4";
      file-decoration-style = "#6c7086";
      commit-decoration-style = "#6c7086 bold box ul";
      hunk-header-style = "file line-number syntax";
      hunk-header-decoration-style = "#6c7086 box ul";
      hunk-header-file-style = "bold";
      hunk-header-line-number-style = "bold #a6adc8";
      line-numbers-left-style = "#6c7086";
      line-numbers-right-style = "#6c7086";
      line-numbers-zero-style = "#6c7086";
      line-numbers-minus-style = "bold #f38ba8";
      line-numbers-plus-style = "bold #a6e3a1";
      minus-style = "syntax #493447";
      minus-emph-style = "bold syntax #694559";
      plus-style = "syntax #394545";
      plus-emph-style = "bold syntax #4e6356";
      map-styles = "bold purple => syntax #5b4e74, bold blue => syntax #445375, bold cyan => syntax #446170, bold yellow => syntax #6b635b";
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  # Colors ported from catppuccin/lazygit's mocha+blue preset
  # (https://github.com/catppuccin/lazygit).
  programs.lazygit = {
    enable = true;
    settings.gui.theme = {
      activeBorderColor = ["#89b4fa" "bold"];
      inactiveBorderColor = ["#a6adc8"];
      searchingActiveBorderColor = ["#f9e2af"];
      optionsTextColor = ["#89b4fa"];
      selectedLineBgColor = ["#313244"];
      inactiveViewSelectedLineBgColor = ["#6c7086"];
      cherryPickedCommitFgColor = ["#89b4fa"];
      cherryPickedCommitBgColor = ["#45475a"];
      markedBaseCommitFgColor = ["#89b4fa"];
      markedBaseCommitBgColor = ["#f9e2af"];
      unstagedChangesColor = ["#f38ba8"];
      defaultFgColor = ["#cdd6f4"];
    };
  };
}

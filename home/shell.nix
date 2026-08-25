{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # oh-my-zsh for its plugin ecosystem and the agnoster prompt theme.
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        # plugin names go here, e.g. "git" "sudo" "fzf"
      ];
    };

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true;
    };

    shellAliases = {
      ade = "gnome-session-quit --logout";

      ls = "eza --group-directories-first";
      ll = "eza -l --git --group-directories-first";
      la = "eza -la --git --group-directories-first";
      lt = "eza --tree --level=2";
      cat = "bat --paging=never";

      g = "git";
      gs = "git status -sb";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate -20";

      # --- the four commands you will type most on NixOS ---
      # rebuild and switch to the new config
      nrs = "sudo nixos-rebuild switch --flake ~/nixcfg";
      # build it but only activate on next boot (safer for risky changes)
      nrb = "sudo nixos-rebuild boot --flake ~/nixcfg";
      # build and test WITHOUT adding a boot entry — reverts on reboot
      nrt = "sudo nixos-rebuild test --flake ~/nixcfg";
      # update all flake inputs (nixpkgs, home-manager)
      nup = "nix flake update --flake ~/nixcfg";

      # edit default.nix with neovim
      defedit = "nvim ~/nixcfg/home/default.nix";
      # edit shell.nix with neovim
      shelledit = "nvim ~/nixcfg/home/shell.nix";
      # edit base.nix with neovim
      baseedit = "nvim ~/nixcfg/modules/base.nix";

      ngen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      ngc = "sudo nix-collect-garbage --delete-older-than 14d";

      # drop into a throwaway shell with packages available
      ns = "nix shell nixpkgs#";
      # run a package once without installing it
      nr = "nix run nixpkgs#";
    };

    initContent = ''
      # uv-managed pythons live here
      export PATH="$HOME/.local/bin:$PATH"

      # nicer word-jumping on the German keyboard
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
    '';
  };

  # Disabled: its init script sets PROMPT after oh-my-zsh, which would
  # silently override the agnoster theme above. Re-enable and drop the
  # omz theme back to "" if you switch back to starship.
  programs.starship = {
    enable = false;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      python.format = "[\${symbol}\${pyenv_prefix}(\${version} )(\\($virtualenv\\) )]($style)";
      nix_shell.format = "[$symbol$state( \\($name\\))]($style) ";
    };
  };

  # Shell history synced and searchable. Genuinely one of the biggest
  # quality-of-life wins when you hop between local and remote boxes.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false; # flip to true once you have an account
      update_check = false;
      style = "compact";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
  };

  programs.bat.enable = true;
  programs.eza.enable = true;
}

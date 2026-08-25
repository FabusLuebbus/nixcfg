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
      ade = "gnome-session-quit --logout --no-prompt";

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
    };

    initContent = ''
      # uv-managed pythons live here
      export PATH="$HOME/.local/bin:$PATH"

      # drop into a throwaway shell with a package available
      # (--impure so NIXPKGS_ALLOW_UNFREE above actually takes effect)
      ns() { nix shell --impure "nixpkgs#$1"; }
      # run a package once without installing it
      nr() { nix run --impure "nixpkgs#$1" -- "''${@:2}"; }

      # nicer word-jumping on the German keyboard
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # non-interactive claude run that splits uncommitted nixcfg changes
      # into well-defined commits per AGENTS.md. Edit/Read are scoped to
      # ~/nixcfg and the Bash allowlist excludes push/reset/checkout/clean/
      # rebase/amend/switch/boot so a bad run can't do anything hard to
      # reverse -- unlisted tool calls just fail closed, since -p mode has
      # no prompt to fall back on.
      nixcfg-cleanup() {
        (
          cd ~/nixcfg && claude -p \
            --allowedTools "Read(~/nixcfg/**) Edit(~/nixcfg/**) Bash(git status) Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git add:*) Bash(git restore --staged:*) Bash(git commit:*) Bash(git apply --cached:*) Bash(sudo nixos-rebuild dry-build:*) Bash(home-manager build:*) Bash(nix flake check:*)" \
            --disallowedTools "Bash(git push:*) Bash(git reset:*) Bash(git checkout:*) Bash(git clean:*) Bash(git rebase:*) Bash(git commit --amend:*) Bash(sudo nixos-rebuild switch:*) Bash(sudo nixos-rebuild boot:*) Bash(rm -rf:*)" \
            "Read AGENTS.md in this repo (~/nixcfg) and follow every rule in it, especially the Git rules section. Run git status and git diff to see the current uncommitted changes across the working tree. Group these changes into well-defined, logically separate commits: one logical change per commit, never bundle unrelated module edits together, and write each commit message to explain WHY the change was made, not just what changed. If a single file mixes multiple unrelated logical changes, split it across commits by temporarily editing the file down to one change at a time, committing, then reapplying the rest -- rather than committing everything from that file at once. Before every commit, review 'git diff --staged' for anything that looks like a secret. Once everything is committed, run the appropriate dry-build to confirm nothing is broken: 'sudo nixos-rebuild dry-build --flake .#framenix' for system-level changes, or 'home-manager build --flake .#fabian' for home-manager-only changes. Do not push. Do not touch system.stateVersion or home.stateVersion. Do not run any destructive git command. If something is ambiguous, or you're blocked by a missing permission, stop and explain what happened instead of guessing."
        )
      }
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

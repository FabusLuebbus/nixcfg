{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    # ---- syntax highlighting: Catppuccin Mocha ----
    # Ported from the old machine's hand-maintained
    # custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh. Set as an
    # option rather than a sourced file so it lands in ZSH_HIGHLIGHT_STYLES
    # before the highlighter is loaded, which is what that file did by hand.
    syntaxHighlighting = {
      enable = true;
      # home-manager always prepends "main" itself, so only the extra goes here.
      highlighters = [ "cursor" ];
      styles =
        let
          text = "fg=#cdd6f4";
          green = "fg=#a6e3a1";
          peach = "fg=#fab387";
          mauve = "fg=#cba6f7";
          red = "fg=#f38ba8";
          yellow = "fg=#f9e2af";
          maroon = "fg=#eba0ac";
        in
        {
          default = text;
          unknown-token = maroon;

          # commands and things that resolve to one
          reserved-word = green;
          alias = green;
          suffix-alias = green;
          global-alias = green;
          function = green;
          command = green;
          builtin = green;
          hashed-command = green;
          precommand = "${green},italic";

          commandseparator = red;
          autodirectory = "${peach},italic";

          path = "${text},underline";
          path_prefix = "${text},underline";
          path_pathseparator = "${red},underline";
          path_prefix_pathseparator = "${red},underline";

          globbing = text;
          history-expansion = mauve;

          command-substitution = text;
          command-substitution-delimiter = text;
          command-substitution-quoted = yellow;
          process-substitution = text;
          process-substitution-delimiter = text;

          single-hyphen-option = peach;
          double-hyphen-option = peach;

          back-quoted-argument = mauve;
          back-quoted-argument-delimiter = red;
          back-quoted-argument-unclosed = maroon;
          back-double-quoted-argument = red;
          back-dollar-quoted-argument = red;

          single-quoted-argument = yellow;
          single-quoted-argument-unclosed = maroon;
          double-quoted-argument = yellow;
          double-quoted-argument-unclosed = maroon;
          rc-quote = yellow;

          dollar-quoted-argument = text;
          dollar-quoted-argument-unclosed = maroon;
          dollar-double-quoted-argument = text;

          assign = text;
          redirection = text;
          named-fd = text;
          numeric-fd = text;
          arg0 = text;
          cursor = text;
          comment = "fg=#585b70";
        };
    };

    # Up/Down filter history by what you have already typed, instead of
    # cycling it blindly. Both the normal-mode (^[[) and application-mode
    # (^[O) arrow sequences are bound, as the old .zshrc did.
    # atuin is handed --disable-up-arrow below so it does not steal these back.
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "^[[A" "^[OA" ];
      searchDownKey = [ "^[[B" "^[OB" ];
    };

    # Nags you when you type out a command you already have an alias for.
    plugins = [
      {
        name = "you-should-use";
        src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
      }
    ];

    # oh-my-zsh for its plugin ecosystem and the agnoster prompt theme.
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git" # git aliases + prompt helpers
        "sudo" # double-tap Esc to prefix the line with sudo
        "docker" # completions
        "docker-compose" # completions
        "dirhistory" # Alt+Arrow through directory history
        "colorize" # `ccat` — syntax-coloured cat
        "copypath" # copy the cwd (or a path) to the clipboard
        "copyfile" # copy a file's contents to the clipboard
        "copybuffer" # Ctrl+O copies the current command line
        "git-auto-fetch" # background `git fetch` inside repos
        "timer" # print how long the last command took
        "virtualenv" # show the active venv in the prompt
        # "pyenv" dropped: Python is uv-only here (see AGENTS.md), and it was
        # already dead config on the old machine — pyenv was never installed.
      ];

      # Settings that oh-my-zsh reads before it sources itself.
      extraConfig = ''
        HYPHEN_INSENSITIVE="true"
        DISABLE_AUTO_TITLE="true"
        COMPLETION_WAITING_DOTS="true"
        HIST_STAMPS="mm/dd/yyyy"
        # The store is read-only, so omz can never update itself in place;
        # it moves with the flake instead. Asking on every shell start is noise.
        zstyle ':omz:update' mode disabled
      '';
    };

    sessionVariables = {
      EDITOR = "nvim";
      # The old config said `batcat` — that is Debian's renamed binary.
      # On NixOS the package and the binary are both just `bat`.
      PAGER = "bat";
      BAT_PAGER = "less -RF";
      MANPAGER = "bat --paging=always";
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
      roschue = "systemctl hibernate";

      # Trailing space is load-bearing: it makes zsh expand the *next* word as
      # an alias too, so `sudo nrs` and friends still resolve.
      sudo = "sudo ";
      neofetch = "fastfetch";
      vim = "nvim";

      ls = "eza --group-directories-first";
      ll = "eza -l --git --group-directories-first";
      la = "eza -la --git --group-directories-first";
      lt = "eza --tree --level=2";
      cat = "bat --paging=never";
      # Same, minus line numbers/header/grid — so a mouse selection copies
      # the file content and nothing else. `copyfile <f>` goes straight to
      # the clipboard when you do not need to look at it first.
      catp = "bat --paging=never --style=plain";

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
      # standard commit flake.lock after nup
      ncf = "cd ~/nixcfg && git add flake.lock && git commit -m 'update flake'";

      # edit default.nix with neovim
      defaultedit = "nvim ~/nixcfg/home/default.nix";
      # edit shell.nix with neovim
      shelledit = "nvim ~/nixcfg/home/shell.nix";
      # edit base.nix with neovim
      baseedit = "nvim ~/nixcfg/modules/base.nix";

      ngen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      ngc = "sudo nix-collect-garbage --delete-older-than 14d";
    };

    initContent = ''
      # Agnoster shows user@host by default. Redefining the segment function
      # here — after oh-my-zsh has loaded the theme — drops the hostname and
      # keeps only the user. Carried over verbatim from the old .zshrc.
      prompt_context() {
        if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
          prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
        fi
      }

      # uv-managed pythons live here
      export PATH="$HOME/.local/bin:$PATH"

      # drop into a throwaway shell with a package available
      # (--impure so NIXPKGS_ALLOW_UNFREE above actually takes effect)
      ns() { nix shell --impure "nixpkgs#$1"; }
      # run a package once without installing it
      nr() { nix run --impure "nixpkgs#$1" -- "''${@:2}"; }

      # is <pkg> part of the config as written? Evaluates the flake rather
      # than grepping the .nix files, so it also sees packages pulled in
      # implicitly by a programs.*.enable, and sees them before a switch has
      # happened. Matches package names, not binaries -- wl-clipboard, not
      # wl-copy. No argument lists everything; exits non-zero when nothing
      # matches, so `haspkg foo && ...` works. Also greps the repo for the
      # file(s) that literally name the package, since that's lost once the
      # eval merges everything into one list; falls back to "implicit" when
      # nothing matches (e.g. pulled in by a programs.*.enable). gnome-shell
      # extensions are declared by their short pkgs.gnomeExtensions attr but
      # eval to a pname prefixed with "gnome-shell-extension-", so the file
      # search retries with that prefix stripped.
      haspkg() {
        local out
        out=$(nix eval --raw ~/nixcfg#nixosConfigurations."$(hostname)" --apply '
          c: let
            fmt = tag: map (p: tag + "\t" + (p.pname or p.name or "?"));
          in builtins.concatStringsSep "\n" (
            fmt "system" c.config.environment.systemPackages
            ++ fmt "home" c.config.home-manager.users.fabian.home.packages
            ++ fmt "extension" (map (e: e.package) (
              c.config.home-manager.users.fabian.programs.gnome-shell.extensions or [ ]
            ))
          )' 2>/dev/null | sort -u | grep -i -- "''${1:-}" | while IFS=$'\t' read -r tag pkg; do
          files=$(grep -rlw --include='*.nix' -- "$pkg" ~/nixcfg | sed "s#$HOME/nixcfg/##" | paste -sd, -)
          if [[ -z $files && $pkg == gnome-shell-extension-* ]]; then
            files=$(grep -rlw --include='*.nix' -- "''${pkg#gnome-shell-extension-}" ~/nixcfg | sed "s#$HOME/nixcfg/##" | paste -sd, -)
          fi
          printf '%s\t%s\t%s\n' "$tag" "$pkg" "''${files:-implicit}"
        done)
        [[ -z $out ]] && return 1
        { printf 'TAG\tPACKAGE\tFILES\n'; printf '%s\n' "$out"; } | awk -F'\t' \
          -v border=$'\e[38;2;108;112;134m' -v head=$'\e[1;38;2;203;166;247m' -v reset=$'\e[0m' '
          NR==1 { for (i=1;i<=NF;i++) { header[i]=$i; w[i]=length($i) } next }
          { n++; for (i=1;i<=NF;i++) { row[n,i]=$i; if (length($i)>w[i]) w[i]=length($i) }; cols=NF }
          END {
            top="╭"; mid="├"; bot="╰"
            for (i=1;i<=cols;i++) {
              bar=sprintf("%*s",w[i]+2,""); gsub(/ /,"─",bar)
              top=top bar (i<cols?"┬":"╮")
              mid=mid bar (i<cols?"┼":"┤")
              bot=bot bar (i<cols?"┴":"╯")
            }
            printf "%s%s%s\n", border, top, reset
            printf "%s│%s", border, reset
            for (i=1;i<=cols;i++) printf " %s%-*s%s %s│%s", head, w[i], header[i], reset, border, reset
            printf "\n%s%s%s\n", border, mid, reset
            for (r=1;r<=n;r++) {
              printf "%s│%s", border, reset
              for (i=1;i<=cols;i++) printf " %-*s %s│%s", w[i], row[r,i], border, reset
              printf "\n"
            }
            printf "%s%s%s\n", border, bot, reset
          }'
      }

      # nicer word-jumping on the German keyboard
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # interactive claude run that splits uncommitted nixcfg changes into
      # well-defined commits per AGENTS.md, pausing to ask when something's
      # ambiguous. Edit/Read are scoped to ~/nixcfg and the Bash allowlist
      # excludes push/reset/checkout/clean/rebase/amend/switch/boot so a bad
      # run can't do anything hard to reverse; unlisted tool calls still
      # prompt for approval since this isn't -p mode.
      nixcfg-cleanup() {
        local prompt="Read AGENTS.md in this repo (~/nixcfg) and follow every rule in it, especially the Git rules section. Run git status and git diff to see the current uncommitted changes across the working tree. Group these changes into well-defined, logically separate commits: one logical change per commit, never bundle unrelated module edits together, and write each commit message to explain WHY the change was made, not just what changed. If a single file mixes multiple unrelated logical changes, split it across commits by temporarily editing the file down to one change at a time, committing, then reapplying the rest -- rather than committing everything from that file at once. Before every commit, review 'git diff --staged' for anything that looks like a secret. Once everything is committed, run the appropriate dry-build to confirm nothing is broken: 'nixos-rebuild dry-build --flake .#$(hostname)' for system-level changes (no sudo needed). Do not push. Do not touch system.stateVersion or home.stateVersion. Do not run any destructive git command. If something is ambiguous, stop and ask me instead of guessing."
        (
          cd ~/nixcfg && claude "$prompt" --model sonnet --effort medium \
            --allowedTools "Read(~/nixcfg/**) Edit(~/nixcfg/**) Bash(git status) Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git add:*) Bash(git restore --staged:*) Bash(git commit:*) Bash(git apply --cached:*) Bash(sudo nixos-rebuild dry-build:*) Bash(home-manager build:*) Bash(nix flake check:*)" \
            --disallowedTools "Bash(git push:*) Bash(git reset:*) Bash(git checkout:*) Bash(git clean:*) Bash(git rebase:*) Bash(git commit --amend:*) Bash(sudo nixos-rebuild switch:*) Bash(sudo nixos-rebuild boot:*) Bash(rm -rf:*)"
        )
      }

      # fuzzy-pick a track from YouTube search results, then hand off to
      # ytp-player (the standalone ytp flake input) for a full-screen audio player:
      # thumbnail-ascii-art or animated speakers visual (toggle with 'v'),
      # a live progress bar, and an arrow-key "up next" queue.
      ytp() {
        local query="$*" url
        [[ -z $query ]] && read -r "query?Search YouTube: "
        [[ -z $query ]] && return 1
        url=$(yt-dlp "ytsearch15:$query" --flat-playlist \
          --print "%(title)s | %(duration_string)s | %(channel)s | %(webpage_url)s" \
        | fzf --delimiter=' \| ' --with-nth=1,2,3 \
        | awk -F' \\| ' '{print $NF}')
        [[ -n $url ]] && ytp-player "$url"
      }

      # plain interactive claude session in ~/nixcfg, same tool
      # restrictions as nixcfg-cleanup but no initial prompt -- for
      # freeform work instead of the scripted commit-splitting flow.
      nixclaude() {
        (
          cd ~/nixcfg && claude --model sonnet --effort medium \
            --allowedTools "Read(~/nixcfg/**) Edit(~/nixcfg/**) Bash(git status) Bash(git status:*) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git add:*) Bash(git restore --staged:*) Bash(git commit:*) Bash(git apply --cached:*) Bash(sudo nixos-rebuild dry-build:*) Bash(home-manager build:*) Bash(nix flake check:*)" \
            --disallowedTools "Bash(git push:*) Bash(git reset:*) Bash(git checkout:*) Bash(git clean:*) Bash(git rebase:*) Bash(git commit --amend:*) Bash(sudo nixos-rebuild switch:*) Bash(sudo nixos-rebuild boot:*) Bash(rm -rf:*)"
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
    # atuin's init runs last in .zshrc and would otherwise rebind Up,
    # clobbering the history-substring-search keys above. Confine it to
    # Ctrl+R: deliberate search stays atuin's, arrows stay substring search.
    flags = [ "--disable-up-arrow" ];
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

  # bat ships the Catppuccin themes built in, so this needs no theme file.
  # Set here rather than via BAT_THEME so `bat` and its use as $PAGER agree.
  programs.bat = {
    enable = true;
    config.theme = "Catppuccin Mocha";
  };
  programs.eza.enable = true;
}

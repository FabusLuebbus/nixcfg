{
  pkgs,
  config,
  ...
}: {
  programs.claude-code = {
    enable = true;

    # Uncomment once you add the unstable overlay (see below). The stable
    # channel only gets backported bugfixes, so claude-code there goes stale
    # fast — this is a tool that ships several releases a week.
    package = pkgs.unstable.claude-code;

    # Writes ~/.claude/settings.json
    settings = {
      # The store is read-only, so the built-in self-updater can never
      # succeed. Turn it off rather than letting it fail on every launch.
      autoUpdates = false;

      # Permissions you're tired of approving every session.
      permissions = {
        allow = [
          "Bash(git status)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(uv run:*)"
          "Bash(uv pip:*)"
          "Bash(ruff:*)"
          "Read(**)"
        ];
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./**/secrets/**)"
          "Bash(rm -rf:*)"
        ];
      };
    };

    # Global CLAUDE.md — instructions that apply in every project.
    # Keep it short; per-project CLAUDE.md files live in the repos themselves.
    context = ''
      ## Environment

      - This machine runs NixOS. There is no apt, no global pip, no system
        Python. Do not suggest `apt install` or `pip install --user`.
      - Python is managed exclusively by `uv`. Use `uv add`, `uv run`,
        `uv sync`. Never `pip install` into a bare environment.
      - Heavy ML work happens on remote machines over SSH, not here.

      ## Style

      - Prefer editing existing files over creating new ones.
      - Do not add explanatory comments unless the logic is non-obvious.
    '';

    # Custom skills, symlinked into ~/.claude/skills/<name>/.
    skills = {
      thermo-nuclear-code-quality-review = ./skills/thermo-nuclear-code-quality-review;
    };

    # MCP servers, declared. Never inline a token here — this file is in git
    # and lands world-readable in the Nix store. Use a wrapper that reads
    # from sops-nix/agenix, or leave the server out until secrets are set up.
    mcpServers = {
      # filesystem = {
      #   command = "npx";
      #   args = [ "-y" "@modelcontextprotocol/server-filesystem"
      #            "${config.home.homeDirectory}/code" ];
      # };
    };
  };

  # Node is NOT required — the nixpkgs package bundles its own runtime.
  # Do not add nodejs to your config on Claude Code's account.
}

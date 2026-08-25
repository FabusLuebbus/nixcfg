# AGENTS.md

Instructions for any AI agent (or human) making changes in this repository.
This is a personal NixOS + home-manager flake config for a single host
(`framenix`, user `fabian`). Mistakes here can leave the machine unbootable
or leak secrets into a public git history, so be conservative.

## Git rules

- **Never rewrite published history.** No `push --force`, `commit --amend`,
  or `rebase` on commits that have been pushed to `origin`. This repo is
  ahead of `origin/main` at times — check `git status` / `git log
  origin/main..HEAD` before assuming local commits are unpublished.
- **Never run destructive git commands** (`reset --hard`, `checkout --`,
  `restore`, `clean -f`) without first checking `git status` and stashing
  or committing anything at risk. This repo carries partially-staged,
  hand-edited work regularly (see mixed staged/unstaged state) — don't
  assume the working tree is disposable.
- **Commit scope**: one logical change per commit. Don't bundle unrelated
  module edits (e.g. a GNOME tweak and an SSH config change) into one
  commit just because they were touched in the same session.
- **Write commit messages that explain *why*, not what** — the diff already
  shows what changed. E.g. "pin nixpkgs-unstable overlay to avoid CUDA
  rebuild churn" beats "update base.nix".
- **Commit your own work once it builds.** After making a change, verify it
  with the appropriate dry-build (see below), then stage and commit it
  yourself rather than leaving it dangling in the working tree — don't wait
  to be asked to commit. Keep the working tree clean at the end of a task:
  no half-finished, uncommitted edits sitting around for the next session
  to untangle. This does not license destructive git operations or pushing
  — committing locally is the default, `git push` still needs explicit
  confirmation.
- **Check for secrets before every commit.** `git diff --staged` and read
  file contents, not just filenames — this config has historically kept
  private keys out of git (see `home/ssh.nix`), and any future secrets
  work should go through `sops-nix` or `agenix`, never plaintext committed
  to this repo.

## Nix / NixOS rules

- **Never touch `system.stateVersion` or `home.stateVersion`.** These are
  set once at install time and pin stateful data compatibility, not a
  version to keep current. Bumping them can silently break databases and
  service state on an existing system. If you see a task that seems to
  require changing them, stop and ask.
- **Build before you claim success.** After editing any `.nix` file, run
  a dry build to catch evaluation errors before telling the user the
  change works:
  ```
  sudo nixos-rebuild dry-build --flake .#framenix
  ```
  Only run `nixos-rebuild switch` (or `boot`) when the user explicitly
  asks to apply the change to the running system — it's a system-wide,
  hard-to-fully-reverse action.
- **home-manager changes are lower-risk than NixOS changes** but still
  verify with `home-manager build --flake .#fabian` (or equivalent) before
  claiming a change is correct, since a broken home-manager generation can
  still lock the user out of their shell.
- **Respect the existing module layering**:
  - `flake.nix` — inputs and top-level wiring only.
  - `hosts/<hostname>/` — hardware + boot config for one machine.
    `hardware-configuration.nix` is machine-generated; don't hand-edit it
    beyond what the installer produced unless you know exactly why.
  - `modules/*.nix` — system-level (NixOS) config, imported by the host.
  - `home/*.nix` — user-level (home-manager) config, imported by
    `home/default.nix`.
  - Keep `environment.systemPackages` (in `modules/base.nix`) minimal —
    only things needed to repair a broken system. Everything else
    (CLI tools, GUI apps, dev tooling) belongs under `home/`.
- **Don't invent new abstractions** (custom lib functions, option
  definitions, extra flake inputs) for a one-host config unless asked.
  Three similar lines in `home/default.nix` beat a premature
  `mkHost`-style function.
- **Preserve the file's existing comment style** when editing nearby code —
  this repo uses short section-header comments (`# ---- name ----`) and
  inline notes explaining *why* a setting exists (e.g. the
  `auto-optimise-store` / disk-fill note in `modules/base.nix`). Match it;
  don't strip it out during unrelated edits.
- **Flake input changes are consequential.** Changing a `nixpkgs` or
  `home-manager` input URL, or running `nix flake update`, can shift huge
  parts of the system. Treat it like any other hard-to-reverse action:
  say what you're doing and why before running it, and prefer updating
  one input at a time over a blanket `nix flake update`.
- **No secrets in `.nix` files, ever** — no API keys, tokens, or passwords
  as plain option values, even temporarily "to test something." Private
  SSH keys are explicitly out of scope for this repo (see the note at the
  top of `home/ssh.nix`); if secrets management comes up, point to
  `sops-nix`/`agenix` rather than committing plaintext.
- **This machine has no `apt`, no system Python, no global `pip`.** Never
  suggest or use those. Python tooling goes through `uv`; anything else
  belongs in a Nix package or `home.packages`.

Read AGENTS.md in this repo (~/nixcfg) and follow every rule in it, especially the Git rules section. Run git status and git diff to see the current uncommitted changes across the working tree. Group these changes into well-defined, logically separate commits: one logical change per commit, never bundle unrelated module edits together, and write each commit message to explain WHY the change was made, not just what changed. If a single file mixes multiple unrelated logical changes, split it across commits by temporarily editing the file down to one change at a time, committing, then reapplying the rest -- rather than committing everything from that file at once. Before every commit, review 'git diff --staged' for anything that looks like a secret.

Once everything is committed, run the dry-build to confirm nothing is broken:

    nixos-rebuild dry-build --flake ~/nixcfg#framenix

Do NOT prefix this with `sudo` -- `dry-build` only evaluates and builds the
closure, it never touches `/etc` or the system profile, so plain user perms
are enough (AGENTS.md says this explicitly). home-manager is wired in as a
NixOS module here, not a standalone flake output, so this one dry-build
covers both system and home-manager changes -- there is no separate
`home-manager build` command to fall back to.

Do not push. Do not touch system.stateVersion or home.stateVersion. Do not
run any destructive git command. If something is ambiguous, stop and ask me
instead of guessing.

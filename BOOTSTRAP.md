# Bootstrapping this config on a new machine

For a fresh install using the NixOS 26.05 ISO.

This flake already defines three hosts: `framenix` (laptop), `desknix`
(nvidia desktop, see `modules/nvidia.nix`), and `servnix` (old laptop
turned headless file/media server, see `modules/server.nix`). If you're
bringing up one of those, skip straight to step 2 (for `servnix`, also see
the data-drive note in `hosts/servnix/default.nix` before step 5). For a
new host beyond these: add a `hosts/<hostname>/` directory modeled on one
of the existing ones, then add
`nixosConfigurations.<hostname> = mkHost "<hostname>" ./home;` in
`flake.nix` (swap `./home` for `./home/server.nix` for a headless box, or
model a new slim home-manager profile on that file).

1. **Install NixOS** normally from the ISO (partition, `nixos-install`, reboot).

2. **Clone this repo.** The freshly-installed system has no `git` and,
   depending on how you partitioned/networked, may not have a network
   connection yet either:
   ```
   # If networking isn't up (check with `ping -c1 nixos.org`), bring it up
   # first — NetworkManager is the default on the graphical ISO / most
   # installs here:
   nmcli device wifi connect "<ssid>" password "<password>"   # wifi
   # or just plug in ethernet, DHCP handles the rest

   nix-shell -p git --run "git clone <this-repo-url> ~/nixcfg"
   ```
   `nix-shell -p git` is enough — nixpkgs' `git` derivation wires up its own
   CA bundle, so HTTPS clones work without any extra SSL setup. If clones
   still fail with a certificate error, you're almost always looking at a
   networking/DNS problem, not a missing cert.

3. **Copy the generated hardware config**, using this machine's hostname
   (`framenix`, `desknix`, or `servnix`):
   ```
   cp /etc/nixos/hardware-configuration.nix ~/nixcfg/hosts/<hostname>/hardware-configuration.nix
   ```
   Then `git add` it right away:
   ```
   git -C ~/nixcfg add hosts/<hostname>/hardware-configuration.nix
   ```
   Nix flakes only see files tracked by git. Skip this and the next step
   fails with a confusing `error: … is not tracked by Git` buried under an
   unrelated-looking `seq`/`modules.nix` stack trace — if you see that,
   this is why. (You don't need to `git add` every subsequent edit before
   a `dry-build`, only a *new* file the first time it's created.)

4. **Check `hosts/<hostname>/default.nix`:**
   - If the installer used GRUB instead of UEFI `systemd-boot`, delete the
     `systemd-boot`/`efi` lines and keep whatever the installer generated.
   - It imports `../../modules/backup.nix` and sets `backupFsUuid` for the
     external backup drive. Find this machine's drive UUID (`lsblk -f` or
     `sudo blkid`) and put it there — `desknix`'s is still a placeholder.

5. **Dry-build to check for evaluation errors (no sudo needed):**
   ```
   nixos-rebuild dry-build --flake ~/nixcfg#<hostname>
   ```

6. **Apply it:**
   ```
   sudo nixos-rebuild switch --flake ~/nixcfg#<hostname>
   ```

7. **Restore what isn't in git:**
   - SSH private keys (not managed here — see `home/ssh.nix`)
   - Any secrets, once `sops-nix`/`agenix` is set up (not yet in this repo)

Never touch `system.stateVersion` / `home.stateVersion` after this point —
see `AGENTS.md` for the full rules governing this repo.

## On `desknix` / any nvidia host: do NOT enable `cudaSupport`

`modules/nvidia.nix` deliberately does **not** set
`nixpkgs.config.cudaSupport = true`. That flag makes Nix build CUDA-enabled
variants of anything in nixpkgs that offers one (`opencv`, `ffmpeg-full`,
...) from source. On the first `desknix` bootstrap this cascaded into a
multi-hour `opencv`+CUDA compile that OOM'd the machine at ~10% done — the
`cuda-maintainers.cachix.org` binary cache mostly targets
`nixpkgs-unstable`, not the `nixos-26.05` pin this repo uses, so those
builds mostly missed cache and compiled locally instead.

You very likely don't need it:
- `hardware.nvidia-container-toolkit.enable = true` (already on) is what
  gives `docker run --gpus all` GPU access — containers bring their own
  CUDA runtime, so this alone is enough for GPU-in-Docker.
- PyTorch/etc. run through `uv`-managed prebuilt wheels (see the `nix-ld`
  block in `modules/dev.nix`), which bundle their own CUDA libs and only
  need the driver, not a Nix-built CUDA toolchain.

If some future package genuinely needs a Nix-built CUDA variant, scope it
to that one derivation (an overlay + `pkgs.cudaPackages`) rather than
flipping the global `cudaSupport` switch — the global flag is what turns a
targeted build into an unbounded, memory-hungry rebuild of your whole
media/graphics stack.

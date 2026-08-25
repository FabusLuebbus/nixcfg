# Bootstrapping this config on a new machine

For a fresh install using the NixOS 26.05 ISO.

This flake already defines two hosts: `framenix` (laptop) and `desknix`
(nvidia desktop, see `modules/nvidia.nix`). If you're bringing up one of
those two, skip straight to step 2. For a third, new host: add a
`hosts/<hostname>/` directory modeled on one of the existing ones, then add
`nixosConfigurations.<hostname> = mkHost "<hostname>";` in `flake.nix`.

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
   (`framenix` or `desknix`):
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

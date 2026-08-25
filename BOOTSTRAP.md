# Bootstrapping this config on a new machine

For a fresh install using the NixOS 26.05 ISO.

This flake already defines two hosts: `framenix` (laptop) and `desknix`
(nvidia desktop, see `modules/nvidia.nix`). If you're bringing up one of
those two, skip straight to step 2. For a third, new host: add a
`hosts/<hostname>/` directory modeled on one of the existing ones, then add
`nixosConfigurations.<hostname> = mkHost "<hostname>";` in `flake.nix`.

1. **Install NixOS** normally from the ISO (partition, `nixos-install`, reboot).

2. **Clone this repo:**
   ```
   nix-shell -p git --run "git clone <this-repo-url> ~/nixcfg"
   ```

3. **Copy the generated hardware config**, using this machine's hostname
   (`framenix` or `desknix`):
   ```
   cp /etc/nixos/hardware-configuration.nix ~/nixcfg/hosts/<hostname>/hardware-configuration.nix
   ```

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

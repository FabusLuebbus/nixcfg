# Bootstrapping this config on a new machine

For a fresh install using the NixOS 26.05 ISO.

1. **Install NixOS** normally from the ISO (partition, `nixos-install`, reboot).

2. **Clone this repo:**
   ```
   nix-shell -p git --run "git clone <this-repo-url> ~/nixcfg"
   ```

3. **Copy the generated hardware config:**
   ```
   cp /etc/nixos/hardware-configuration.nix ~/nixcfg/hosts/laptop/hardware-configuration.nix
   ```

4. **Edit `flake.nix`** — set `username` and `hostname` for this machine.
   If this isn't the `laptop` host, add a new directory under `hosts/`
   modeled on `hosts/laptop/` and point `nixosConfigurations` at it.

5. **Check `hosts/laptop/default.nix`** — if the installer used GRUB
   instead of UEFI `systemd-boot`, delete the `systemd-boot`/`efi` lines
   and keep whatever the installer generated.

6. **Dry-build to check for evaluation errors (no sudo needed):**
   ```
   nixos-rebuild dry-build --flake ~/nixcfg#<hostname>
   ```

7. **Apply it:**
   ```
   sudo nixos-rebuild switch --flake ~/nixcfg#<hostname>
   ```

8. **Restore what isn't in git:**
   - SSH private keys (not managed here — see `home/ssh.nix`)
   - Any secrets, once `sops-nix`/`agenix` is set up (not yet in this repo)

Never touch `system.stateVersion` / `home.stateVersion` after this point —
see `AGENTS.md` for the full rules governing this repo.

{ lib, pkgs, osConfig, ... }:

let
  # Not packaged in nixpkgs (extensions.gnome.org still serves it, but the
  # nixpkgs generator drops extensions that don't declare support for a
  # recent shell version, and this one tops out at 42). Packaged by hand
  # against the same e.go download the other extensions use.
  cpupower = pkgs.stdenv.mkDerivation rec {
    pname = "gnome-shell-extension-cpupower";
    version = "27";
    uuid = "cpupower@mko-sl.de";

    src = pkgs.fetchzip {
      url = "https://extensions.gnome.org/extension-data/cpupowermko-sl.de.v${version}.shell-extension.zip";
      hash = "sha256-ppGH1x6C4UCDuYG/qVMzPzFkKK9BeGLi9bTM5yDJ4yA=";
      stripRoot = false;
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/gnome-shell/extensions/${uuid}
      cp -r . $out/share/gnome-shell/extensions/${uuid}
      runHook postInstall
    '';

    passthru.extensionUuid = uuid;

    meta = with lib; {
      description = "Manage the CPU's frequency scaling driver from GNOME Shell";
      homepage = "https://github.com/deinstapel/cpupower";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
    };
  };

  # desknix (the nvidia desktop) has a different networking.hostName and
  # falls out of this check automatically.
  isLaptop = osConfig.networking.hostName == "framenix";
in
{
  programs.gnome-shell = {
    enable = true;
    extensions = map (package: { inherit package; }) (
      (with pkgs.gnomeExtensions; [
        arcmenu
        astra-monitor
        caffeine
        hibernate-status-button
        impatience
        just-perfection
        pomodoro-timer
        rounded-window-corners-reborn
        tiling-shell
      ])
      ++ [ cpupower ]
      ++ lib.optionals isLaptop [ pkgs.gnomeExtensions.battery-time-2 ]
    );
  };
}

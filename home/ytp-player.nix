{
  pkgs,
  inputs,
  ...
}: let
  python = pkgs.python311;
  ytpPackage = python.pkgs.buildPythonApplication {
    pname = "ytp";
    version = "0.1.0";
    pyproject = true;
    src = inputs.ytp;
    build-system = [python.pkgs.hatchling];
    dependencies = [python.pkgs.blessed];
  };
  # Nix store sources are immutable. Seed an editable runtime copy in XDG data
  # so ytp can persist EQ changes without modifying the packaged defaults.
  ytpPlayer = pkgs.writeShellScriptBin "ytp-player" ''
    config_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/ytp"
    mkdir -p "$config_dir"
    for config_file in eq.json speaker_tall.txt speaker_med.txt speaker_small.txt; do
      config_path="$config_dir/$config_file"
      if [[ -L "$config_path" && "$(readlink "$config_path")" == /nix/store/* ]]; then
        rm "$config_path"
      fi
      if [[ ! -e "$config_path" ]]; then
        cp "${inputs.ytp}/config/$config_file" "$config_path"
      fi
      if [[ "$config_file" == eq.json ]]; then
        chmod u+rw "$config_path"
      fi
    done
    export YTP_CONFIG_DIR="$config_dir"
    export YTP_MPRIS_SCRIPT="${pkgs.mpvScripts.mpris}/share/mpv/scripts/mpris.so"
    exec ${ytpPackage}/bin/ytp "$@"
  '';
in {
  home.packages = [ytpPlayer];
}

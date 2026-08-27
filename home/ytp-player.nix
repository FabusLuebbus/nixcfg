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
  # Nix store sources are immutable. Keep the repo's defaults, but place the
  # editable runtime copy in XDG data so EQ changes can be saved.
  ytpPlayer = pkgs.writeShellScriptBin "ytp-player" ''
    export YTP_CONFIG_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/ytp"
    exec ${ytpPackage}/bin/ytp "$@"
  '';
in {
  home.file.".local/share/ytp/eq.json".source = "${inputs.ytp}/config/eq.json";
  home.file.".local/share/ytp/speaker_tall.txt".source = "${inputs.ytp}/config/speaker_tall.txt";
  home.file.".local/share/ytp/speaker_med.txt".source = "${inputs.ytp}/config/speaker_med.txt";
  home.file.".local/share/ytp/speaker_small.txt".source = "${inputs.ytp}/config/speaker_small.txt";
  home.packages = [ytpPlayer];
}

{ pkgs }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    yubikey-manager
  ];
}

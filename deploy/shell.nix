{ pkgs }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    agenix-rekey
    nixos-anywhere
    nixos-rebuild
    ragenix
  ];
}

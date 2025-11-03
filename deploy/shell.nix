{ pkgs }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    agenix-rekey
    nixos-anywhere
    nixos-rebuild
    ragenix
  ];
}

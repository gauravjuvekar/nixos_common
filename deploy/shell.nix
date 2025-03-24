{ pkgs }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs;
    [
      nixos-anywhere
      nixos-rebuild
      ragenix
    ];
}

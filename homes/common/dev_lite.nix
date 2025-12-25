{ pkgs, ... }:
let
  myYdiffOverlay = final: prev: {
    ydiff = prev.ydiff.overrideAttrs (old: {
      src = prev.fetchFromGitHub {
        owner = "gauravjuvekar";
        repo = "ydiff";
        rev = "c68e7d7259bb3df332ca0d98c8bec75729a98457";
        hash = "sha256-NKMuuKPY/FEOszeJZ0P0xyO/oTxbVvJD+AFfnit5zLM=";
      };
      doInstallCheck = false;
    });
  };
  myPkgs = pkgs.extend myYdiffOverlay;
in
{
  imports = [
    ./neovim/neovim.nix
    ./shell.nix
  ];

  home.packages = with myPkgs; [
    ansible
    ansible-lint
    hexedit
    hexyl
    jsonschema
    patchutils
    repgrep
    socat
    xxd
    ydiff
  ];
}

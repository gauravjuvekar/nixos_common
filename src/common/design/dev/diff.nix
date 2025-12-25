{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
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
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  config =
    {
      "home-manager" = {
        home.packages =
          lib.lists.optionals hostinfo.isLocalInteractive [
            pkgs.nix-diff
            pkgs.nvd
            pkgs.patchutils
            myPkgs.ydiff
          ]
          ++ lib.lists.optionals hostinfo.isLocalGraphical [
            pkgs.meld
          ];

        home.shellAliases = {
          "dy" = "ydiff -H change -H whole-line -s -w0 --wrap --";
        };
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

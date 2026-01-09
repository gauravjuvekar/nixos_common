{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
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
        home.packages = lib.lists.flatten (
          lib.lists.optionals hostinfo.isLocalGraphical [
            pkgs.file-roller
            pkgs.mate.engrampa
          ]
          ++ lib.lists.optionals hostinfo.isLocalInteractive [
            pkgs.bzip2
            pkgs.bzip3
            pkgs.gnutar
            pkgs.gzip
            pkgs.p7zip
            pkgs.pigz
            pkgs.ripunzip
            pkgs.unzip
            pkgs.xz
            pkgs.zstd
          ]
        );
      };

      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

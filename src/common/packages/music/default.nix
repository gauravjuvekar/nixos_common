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

  domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
in
{
  config =
    lib.mkIf (domain_is_personal && hostinfo.isLocalGraphical)
      {
        "home-manager" = {
          home.packages = [
            pkgs.clementine
            pkgs.kid3-qt
            pkgs.python3Packages.eyed3
          ];
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

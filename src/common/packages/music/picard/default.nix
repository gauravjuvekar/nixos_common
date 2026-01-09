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
            pkgs.chromaprint
            pkgs.picard
          ];
          xdg.configFile."MusicBrainz/Picard.ini".source = ./Picard.ini;
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

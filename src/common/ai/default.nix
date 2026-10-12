{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  usageinfo =
    {
      home-manager = osConfig.usageinfo;
      nixos-system = config.usageinfo;
    }
    ."${moduleContext}";

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
    {
      "home-manager" = {
        home.packages = lib.mkIf (domain_is_personal && hostinfo.isLocalGraphical) [
          pkgs.codex
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

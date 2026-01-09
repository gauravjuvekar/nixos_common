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
    {
      "home-manager" = {
        programs.mr.enable = true;
        programs.mr.settings = lib.mkIf domain_is_personal {
          ".config/home-manager" = {
            checkout = "git clone git@github.com/gauravjuvekar/nixos_common.git";
          };
        };
      };

      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

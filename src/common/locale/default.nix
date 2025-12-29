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
      };
      "nixos-system" = {
        i18n = lib.mkIf hostinfo.isLocalInteractive {
          defaultLocale = "en_US.UTF-8";
          extraLocaleSettings = {
            LC_COLLATE = "C.UTF-8";
            LC_TIME = "en_DK.UTF-8";
          };
        };
      };
    }
    ."${moduleContext}";
}

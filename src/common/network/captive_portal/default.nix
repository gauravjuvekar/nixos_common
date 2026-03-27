{
  config,
  lib,
  moduleContext,
  osConfig ? null,
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
      "home-manager" = { };
      "nixos-system" = lib.mkIf hostinfo.isLaptop {
        programs.captive-browser.enable = true;
      };
    }
    ."${moduleContext}";
}

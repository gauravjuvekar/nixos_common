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

      "nixos-system" = lib.mkIf hostinfo.isLaptop {
        programs.system-config-printer.enable = true;

        services.printing = {
          enable = true;
          cups-pdf.enable = true;
          drivers = [
            pkgs.brlaser
            pkgs.gutenprint
            pkgs.gutenprintBin
          ];
        };
      };
    }
    ."${moduleContext}";
}

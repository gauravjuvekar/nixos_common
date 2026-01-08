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
    lib.mkIf hostinfo.isLocalGraphical
      {
        "home-manager" = {
          programs.alacritty = {
            enable = true;
            settings = {
              general.import = [
                "${pkgs.alacritty-theme}/alabaster_dark.toml"
              ];
              scrolling = {
                history = 100000;
              };
              font = {
                normal = {
                  family = "DroidSansMDotted Nerd Font";
                  style = "Regular";
                };
              };
            };
          };
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

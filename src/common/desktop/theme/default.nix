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
        "home-manager" =
          let
            gtkTheme = "Mint-Y-Dark";
          in
          {
            gtk = {
              enable = true;
              colorScheme = "dark";
              theme = {
                name = gtkTheme;
                package = pkgs.mint-themes;
              };
            };
            home.sessionVariables = {
              GTK_THEME = gtkTheme;
            };
            home.packages = [
              pkgs.mint-x-icons
            ];
          };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

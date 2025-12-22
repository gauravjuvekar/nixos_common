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
    lib.mkIf hostinfo.isLocalInteractive
      {
        "home-manager" = {
          home.packages = [
            pkgs.pipewire
            pkgs.pulseaudio
            pkgs.wireplumber
          ]
          ++ (
            if hostinfo.isLocalGraphical then
              [
                pkgs.audacity
                pkgs.pwvucontrol
                pkgs.qpwgraph
              ]
            else
              [ ]
          );
        };
        "nixos-system" = {
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            extraLv2Packages = [ pkgs.lsp-plugins ];
            pulse.enable = true;
            wireplumber = {
              enable = true;
              extraLv2Packages = [ pkgs.lsp-plugins ];
            };
          };
          services.pulseaudio.enable = false;
        };
      }
      ."${moduleContext}";
}

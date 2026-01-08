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
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        programs.gpg = {
          enable = true;
          mutableKeys = true;
          mutableTrust = true;
        };
        services.gpg-agent = {
          enable = true;
          enableBashIntegration = true;
          extraConfig = ''
            pinentry-program ${pkgs.pinentry-curses}/bin/pinentry
          '';
        };
        home.packages = with pkgs; [
          gnupg
          pinentry-curses
        ];
      };
      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

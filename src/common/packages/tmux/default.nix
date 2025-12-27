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
        programs.tmux = {
          enable = true;
          clock24 = true;
          escapeTime = 10;
          extraConfig = ''
            bind-key -T copy-mode-vi 'v' send -X begin-selection
            bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
            set -as terminal-features "alacritty:RGB"
          '';
          focusEvents = true;
          historyLimit = 10000;
          keyMode = "vi";
          mouse = hostinfo.isLocalGraphical;
          terminal = "screen-256color";
        };

        home.packages = [
          pkgs.screen
        ];

        home.file = {
          ".screenrc".text = ''
            escape ^Jj
          '';
        };
      };
      "nixos-system" = {
        environment.systemPackages = [
          pkgs.tmux
        ];
      };
    }
    ."${moduleContext}";
}

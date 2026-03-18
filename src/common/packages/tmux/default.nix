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
          baseIndex = 1;
          clock24 = true;
          escapeTime = 10;
          extraConfig = ''
            bind-key -T copy-mode-vi 'v' send -X begin-selection
            bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

            set-option -g renumber-windows on

            set-option -g update-environment "${
              lib.strings.concatStringsSep " " [
                # These defaults come from https://github.com/tmux/tmux/blob/bef4865d91ff8e549a3a4d63563f0ef1a39a1a39/options-table.c#L1026-L1027
                "DISPLAY"
                "KRB5CCNAME"
                "MSYSTEM"
                "SSH_ASKPASS"
                "SSH_AUTH_SOCK"
                "SSH_AGENT_PID"
                "SSH_CONNECTION"
                "WINDOWID"
                "XAUTHORITY"

                # Address https://github.com/alacritty/alacritty/issues/8876
                "ALACRITTY_WINDOW_ID"

                # Allow :set status-style from direnv to differentiate between
                # different workspaces
                "TMUX_SESSION_STATUS_STYLE"
              ]
            }"

            set-hook -g session-created {
              if-shell '[ -n "$TMUX_SESSION_STATUS_STYLE" ]' {
                set-option -s status-style "#{TMUX_SESSION_STATUS_STYLE}"
              } {
                set-option -s status-style bg=green,fg=black
              }
            }

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

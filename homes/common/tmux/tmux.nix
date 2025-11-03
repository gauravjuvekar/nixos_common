{ ... }:
{
  programs.tmux =
    {
      enable = true;
      clock24 = true;
      escapeTime =  10;
      extraConfig =
        ''
          bind-key -T copy-mode-vi 'v' send -X begin-selection
          bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
          set -as terminal-features "alacritty:RGB"
        '';
      focusEvents = true;
      historyLimit = 10000;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";
    };
}

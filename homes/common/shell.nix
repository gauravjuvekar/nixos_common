{ ... }:
{
  programs.bash.enable = true;

  home.shellAliases = {
    "e" = "nvim";
    "v" = "nvim -R";
    "vi" = "nvim";

    "f" = "fzf";
    "fn" = "find . -name";

    "ac" = "ag --cc";
    "ah" = "ag --hh";
    "rgc" = "rg --color=always";

    "LS" = "ls";
    "SL" = "ls";
    "sl" = "ls";

    "clip" = "xclip -sel clip";
    "o" = "xdg-open";
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [
      "--cmd"
      "j"
    ];
  };
  programs.dircolors.enable = true;
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.fzf.enable = true;

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
      enter_accept = false;
    };
  };
}

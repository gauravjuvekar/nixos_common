{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        # "${pkgs.alacritty-theme}/hyper.toml" // For OLED: TODO specializations
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
}

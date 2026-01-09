{ pkgs, ... }:
let
  gtkTheme = "Mint-Y-Dark";
in
{
  home.packages = with pkgs; [
    blueberry
    screenkey
    shutter
  ];

  gtk.theme = gtkTheme;
  home.sessionVariables = {
    GTK_THEME = gtkTheme;
  };
}

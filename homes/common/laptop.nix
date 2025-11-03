{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brightnessctl
    gnome-power-manager
  ];
}

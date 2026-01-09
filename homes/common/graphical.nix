{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blueberry
    screenkey
    shutter
  ];
}

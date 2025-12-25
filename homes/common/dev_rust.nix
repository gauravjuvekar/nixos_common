{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ra-multiplex
  ];
}

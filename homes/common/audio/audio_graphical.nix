{ pkgs, ... }:
{
  home.packages = with pkgs;
    [
      audacity
      pwvucontrol
      qpwgraph
    ];
}

{ pkgs, ... }:
{
  imports = [
    ./dev_lite.nix
  ];

  home.packages = with pkgs; [
    flamegraph
    heaptrack
    hotspot
    hyperfine
  ];
}

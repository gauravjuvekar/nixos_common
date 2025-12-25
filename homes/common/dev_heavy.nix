{ pkgs, ... }:
{
  imports = [
    ./dev_k8s.nix
    ./dev_lite.nix
    ./dev_rust.nix
  ];

  home.packages = with pkgs; [
    flamegraph
    heaptrack
    hotspot
    hyperfine
  ];
}

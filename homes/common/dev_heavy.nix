{ pkgs, ... }:
{
  imports = [
    ./dev_cxx.nix
    ./dev_k8s.nix
    ./dev_lite.nix
    ./dev_rust.nix
  ];

  home.packages = with pkgs; [
    flamegraph
    gnumake
    heaptrack
    hotspot
    hyperfine
  ];
}

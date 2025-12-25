{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo-flamegraph
    ra-multiplex
  ];
}

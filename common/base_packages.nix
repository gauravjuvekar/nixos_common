{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    fd
    parallel
    ripgrep
    tmux
    tree
    wget
  ];
}

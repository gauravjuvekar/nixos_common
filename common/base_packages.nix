{ pkgs, ... }:
{
  # nano is horror
  programs.neovim = {
    defaultEditor = true;
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    curl
    fd
    nh
    nix-du
    nix-output-monitor
    nix-tree
    parallel
    ripgrep
    tmux
    tree
    wget
  ];
}

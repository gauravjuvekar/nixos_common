{ config, pkgs, lib, ... }:
{
  # nano is horror
  programs.neovim =
    {
      defaultEditor = true;
      enable = true;
    };

  environment.systemPackages = with pkgs;
    [
      curl
      fd
      git
      nix-diff
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

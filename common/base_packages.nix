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
      fd
      git
      nix-output-monitor
      parallel
      ripgrep
      tmux
      tree
      wget
    ];
}

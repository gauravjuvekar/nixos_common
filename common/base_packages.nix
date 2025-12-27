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
    parallel
    ripgrep
    tmux
    tree
    wget
  ];
}

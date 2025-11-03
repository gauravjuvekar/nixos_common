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
    git
    nh
    nix-diff
    nix-du
    nix-output-monitor
    nix-tree
    nvd
    parallel
    ripgrep
    tmux
    tree
    wget
  ];
}

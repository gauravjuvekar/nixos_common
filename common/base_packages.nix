{ pkgs, ... }:
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
      #nix-du Bug https://github.com/symphorien/nix-du/issues/23
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

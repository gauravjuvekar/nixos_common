{ pkgs, ... }:
{
  imports = [
    ./neovim/neovim.nix
    ./shell.nix
  ];

  home.packages = with pkgs; [
    ansible
    ansible-lint
    jsonschema
    repgrep
    socat
  ];
}

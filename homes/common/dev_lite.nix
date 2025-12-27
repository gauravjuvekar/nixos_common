{ pkgs, ... }:
{
  imports = [
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

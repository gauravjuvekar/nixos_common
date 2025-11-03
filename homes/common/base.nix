{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./options.nix
  ];
  programs.home-manager.enable = true;
}

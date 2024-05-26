{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./base_boot.nix
      ./base_etc.nix
      ./base_packages.nix
    ];

  nix.extraOptions = ''
      extra-experimental-features = flakes
      extra-experimental-features = nix-command
      extra-experimental-features = repl-flake
    '';
}

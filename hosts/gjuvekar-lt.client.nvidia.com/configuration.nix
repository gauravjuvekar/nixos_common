{ config, pkgs, lib, ... }:
{
  imports =
    [
      ../../common/base.nix
      ../../common/graphical.nix
      ../../common/interactive.nix
      ../../common/physical_access.nix
    ];
}

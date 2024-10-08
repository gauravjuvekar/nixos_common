{ lib, ... }:
{
  imports =
    [
      ./keyboards_interactive.nix
      ./keyd.nix
    ];

  i18n.defaultLocale = "en_US.UTF-8";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
}

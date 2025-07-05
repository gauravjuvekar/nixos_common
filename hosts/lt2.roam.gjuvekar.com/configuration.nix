{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../common/age.nix
      ../../common/base.nix
      ../../common/base_personal.nix
      ../../common/graphical.nix
      ../../common/interactive.nix
      ../../common/physical_access.nix
      ../../common/user_personal.nix
      ./snapper.nix
    ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "lt2";
  networking.domain = "roam.gjuvekar.com";

  time.timeZone = "America/Los_Angeles";

  programs.gnupg.agent =
    {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

  services.gnome.gnome-keyring.enable = true;

  system.copySystemConfiguration = false;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAax1ZKIUjYddougXLZ2HSU+6s17YLg6N+cFq3DN+kQ0 root@nixos";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}

{ pkgs, ... }:
{
  imports = [
    ./wireshark.nix
  ];

  environment.systemPackages = with pkgs; [
    arandr
    xorg.xkill
  ];

  security.pam.services = {
    hyprlock = { };
    swaylock = { };
    sddm = {
      enableGnomeKeyring = true;
    };
  };

  services.libinput.enable = true;

  services.gnome.gnome-keyring.enable = true;
}

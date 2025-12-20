{ pkgs, ... }:
{
  imports = [
    ./cinnamon/cinnamon.nix
    ./sound.nix
    ./wireshark.nix
  ];

  environment.systemPackages = with pkgs; [
    arandr
    vanilla-dmz # 1 cursor theme requried for gdm
    xorg.xkill
  ];

  programs.niri.enable = true;
  security.pam.services = {
    hyprlock = { };
    swaylock = { };
    sddm = {
      enableGnomeKeyring = true;
    };
  };

  services.libinput.enable = true;

  services.gnome.gnome-keyring.enable = true;
  services.displayManager = {
    gdm.enable = true;
  };
}

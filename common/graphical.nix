{ pkgs, ... }:
{
  imports =
    [
      ./sound.nix
      ./cinnamon/cinnamon.nix
    ];

  environment.systemPackages = with pkgs;
    [
      arandr
      vanilla-dmz # 1 cursor theme requried for gdm
      xorg.xkill
    ];

  programs.hyprland =
    {
      enable = true;
      withUWSM = true;
    };
  programs.niri.enable = true;
  security.pam.services =
    {
      hyprlock = {};
      swaylock = {};
      sddm =
        {
          enableGnomeKeyring = true;
        };
    };

  services.libinput.enable = true;

  services.gnome.gnome-keyring.enable = true;
  services.displayManager.sddm.enable = true;
  services.xserver =
    {
      enable = true;
      displayManager.gdm.enable = false;
    };
}

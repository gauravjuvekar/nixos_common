{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs;
    [
      arandr
      pavucontrol
      pipewire
      vanilla-dmz # 1 cursor theme requried for gdm
      xorg.xkill
    ];
  programs.hyprland.enable = true;
  services.libinput.enable = true;
  services.xserver =
    {
      enable = true;
      displayManager.gdm.enable = false;
      displayManager.sddm.enable = true;
      desktopManager.cinnamon.enable = true;
    };
  xdg.portal =
    {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal ];
    };

  hardware.pulseaudio.enable = true;
  sound.enable = true;
}

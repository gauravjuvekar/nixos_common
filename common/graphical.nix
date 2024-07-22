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

  services.displayManager.sddm.enable = true;
  services.xserver =
    {
      enable = true;
      displayManager.gdm.enable = false;
      desktopManager.cinnamon.enable = true;
    };

  xdg.portal =
    {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal ];
    };

  hardware.pulseaudio.enable = true;
}

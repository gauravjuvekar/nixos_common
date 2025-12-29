{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    arandr
    xorg.xkill
  ];

  services.libinput.enable = true;

  services.gnome.gnome-keyring.enable = true;
}

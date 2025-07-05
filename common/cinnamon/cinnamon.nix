{ lib, ... }:
{
  services.xserver.desktopManager.cinnamon.enable = true;

  # Crap enabled by cinnamon by default
  services =
    {
      gnome.evolution-data-server.enable = lib.mkForce false;

      # Crashes on wayland, should be started manually on laptops if needed
      touchegg.enable = false;
    };
}

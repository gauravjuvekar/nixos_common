{ ... }:
{
  imports =
    [
      ../../common/age.nix
      ../../common/base.nix
      ../../common/base_laptop.nix
      ../../common/graphical.nix
      ../../common/interactive.nix
      ../../common/networking_open_wifi.nix
      ../../common/physical_access.nix
    ];

  networking.hostName = "gjuvekar-lt";
  networking.domain = "client.nvidia.com";
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUN3O9Pbm+oBEOeqcnsz/MESESfEkuGa5Nxp1YnpNj3 root@gjuvekar-lt";
}

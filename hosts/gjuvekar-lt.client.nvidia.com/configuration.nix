{ ... }:
{
  imports = [
    ../../common/age.nix
    ../../common/graphical.nix
    ../../common/interactive.nix
    ../../common/networking_open_wifi.nix
    ../../common/physical_access.nix
  ];

  hostinfo.isLaptop = true;
  usageinfo = {
    devLangs = [
      "cxx"
      "python"
      "rust"
    ];
    devTools = [
      "binary"
      "containers"
      "db"
      "memory"
      "perf"
    ];
    cadTools = [
      "2d"
    ];
  };

  networking.hostName = "gjuvekar-lt";
  networking.domain = "client.nvidia.com";
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUN3O9Pbm+oBEOeqcnsz/MESESfEkuGa5Nxp1YnpNj3 root@gjuvekar-lt";
}

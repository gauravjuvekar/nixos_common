{ ... }:
{
  imports = [
    ../../common/age.nix
  ];

  hostinfo = {
    isLaptop = true;
    hostname = "gjuvekar-lt";
    domainname = "client.nvidia.com";
    primaryUsername = "gjuvekar";
  };

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
      "network"
      "perf"
    ];
    cadTools = [
      "2d"
    ];
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUN3O9Pbm+oBEOeqcnsz/MESESfEkuGa5Nxp1YnpNj3 root@gjuvekar-lt";
}

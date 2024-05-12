{ config, pkgs, lib, ... }:
{
  environment.etc =
    {
      "lvm/lvm.conf" = lib.mkForce
        {
          source = ./files/lvm.conf;
          mode = "0600";
        };
    };
}

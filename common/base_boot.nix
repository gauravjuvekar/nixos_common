{ config, pkgs, lib, ... }:
{
  boot.initrd.systemd.contents =
    {
      "/etc/lvm/lvm.conf".source = ./files/lvm.conf;
    };

  boot.initrd.systemd.enable = true;
  boot.initrd.services.lvm.enable = true;
}

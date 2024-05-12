{ config, pkgs, lib, ... }:
{
  users.users.gaurav =
    {
      isNormalUser = true;
      home = "/home/gaurav";
      uid = 1001;
      extraGroups =
        [
          "networkmanager"
          "wheel"
        ];
    };
  users.groups.gaurav.gid = 1001;
}

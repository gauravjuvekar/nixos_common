{ config, pkgs, ... }:
{
  systemd.services."xe-daemon".enable = false;

  environment.etc."lvm/lvm.conf" =
    {
      text =
        ''
          devices {
            scan_lvs = 1
          }
        '';
      mode = "0600";
    };

  boot.kernelModules = [ "dm-raid" "dm-integrity" ];
}

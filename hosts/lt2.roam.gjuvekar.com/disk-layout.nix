{ lib, ... }:
{
  disko.devices =
    {
      disk =
        {
          phy0 =
            {
              type = "disk";
              device = "/dev/disk/by-id/nvme-eui.0025384b41a07235";
              content =
                {
                  type = "gpt";
                  partitions =
                    {
                      ESP =
                        {
                          size = "1G";
                          type = "EF00"; # EFI system partition
                          content =
                            {
                              type = "filesystem";
                              format = "vfat";
                              mountpoint = "/boot/efi";
                            };
                          priority = 1;
                        };
                      phyBoot =
                        {
                          size = "4G";
                          priority = 2;
                          content =
                            {
                              type = "luks";
                              name = "cryptBoot";
                              extraFormatArgs =
                                [
                                  "--type luks1"
                                ];
                              settings.allowDiscards = true;
                              content =
                                {
                                  type = "filesystem";
                                  format = "ext4";
                                  mountpoint = "/boot";
                                };
                            };
                        };
                    }
                    //
                    (
                      let
                        range = (lib.lists.range 1 59);
                        last = lib.lists.last range;
                        first = lib.lists.dropEnd 1 range;
                        mkName = (n: "phyMain" + (builtins.toString n));
                        mkValue = ({n, size}:
                          {
                            priority = 10 + n;
                            size = size;
                            content =
                              {
                                type = "lvm_pv";
                                vg = "vgDisk0";
                              };
                          });
                      in
                      builtins.listToAttrs
                        (
                          [
                            {
                              name = mkName last;
                              value = mkValue {n=last; size="100%";};
                            }
                          ] ++
                          builtins.map
                            (n:
                              {
                                name = mkName n;
                                value = mkValue {n=n; size="32G";};
                              }
                            )
                            first
                        )
                    );
                };
            };
        };
      lvm_vg =
        {
          vgDisk0 =
            {
              type = "lvm_vg";
              lvs =
                {
                  lvCryptMainBase =
                    {
                      size = "100%";
                      content =
                        {
                          type = "luks";
                          name = "cryptMain";
                          extraFormatArgs =
                            [
                              # reserve initial slots for systemd-cryptenroll
                              "--key-slot 2"
                            ];
                          settings.allowDiscards = true;
                          content =
                            {
                              type = "lvm_pv";
                              vg = "vgOs";
                            };
                        };
                    };
                };
            };
          vgOs =
            {
              type = "lvm_vg";
              lvs =
                {
                  lvSwap =
                    {
                      size = "32G";
                      content =
                        {
                          type = "swap";
                          resumeDevice = true;
                        };
                    };
                  lvRoot =
                    {
                      size = "128G";
                      content =
                        {
                          type = "btrfs";
                          subvolumes =
                            {
                              "@root" =
                                {
                                  mountpoint = "/";
                                };
                              "@nix" =
                                {
                                  mountpoint = "/nix";
                                };
                              "@var-log" =
                                {
                                  mountpoint = "/var/log";
                                };
                            };
                        };
                    };
                  lvHome =
                    {
                      size = "1T";
                      content =
                        {
                          type = "btrfs";
                          subvolumes =
                            {
                              "@" =
                                {
                                  mountpoint = "/home";
                                };
                              "@snapshots" =
                                {
                                  mountpoint = "/home/.snapshots";
                                };
                            };
                        };
                    };
                };
            };
        };
    };
}

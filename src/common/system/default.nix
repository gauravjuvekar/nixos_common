{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  ...
}:
let
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  config =
    let
      sys_and_user_config = {
        Manager.StatusUnitFormat = "combined";
      };
    in
    {
      "home-manager" = {
        systemd.user.settings = sys_and_user_config;
      };

      "nixos-system" = {
        boot.kernel.sysctl = lib.mkIf hostinfo.isLocalInteractive {
          "kernel.sysrq" = 1;
        };

        boot = {
          swraid.enable = true;

          loader = {
            efi.canTouchEfiVariables = true;
            grub = {
              enable = true;
              copyKernels = true;
              device = "nodev";
              efiSupport = true;
              enableCryptodisk = true;
            };
            timeout = 10;
          };

          initrd = {
            kernelModules = [
              "dm-snapshot"
              "dm-integrity"
              "dm-raid"
            ];
            supportedFilesystems = [
              "btrfs"
              "ext4"
              "vfat"
            ];

            services.lvm.enable = true;

            systemd = {
              enable = true;
              emergencyAccess = true;
              settings.Manager = {
                DefaultDeviceTimeoutSec = 20;
                StatusUnitFormat = "name";
              };
            };
          };
        };

        programs.fuse.userAllowOther = true;

        systemd.settings = sys_and_user_config;
      };
    }
    ."${moduleContext}";
}

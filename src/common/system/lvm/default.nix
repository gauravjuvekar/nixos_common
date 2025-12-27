{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
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
    {
      "home-manager" = {
      };
      "nixos-system" =
        let
          udevRules = ''
            ENV{LVM_PVSCAN_ON_LVS}="1"
          '';

          udevPackages = [
            (pkgs.writeTextFile {
              name = "my-lvm-initrd-udev-rules";
              destination = "/etc/udev/rules.d/10-local.rules";
              text = udevRules;
            })
          ];
        in
        {
          boot.initrd = {
            services = {
              udev = {
                rules = udevRules;
                packages = udevPackages;
              };
            };

            systemd = {
              services = {
                # Bug https://github.com/NixOS/nixpkgs/issues/428775
                "systemd-udevd".after = [ "systemd-modules-load.service" ];
              };
              contents = {
                "/etc/lvm/lvm.conf".source = ./lvm.conf;
              };
            };
          };

          environment.etc = {
            "lvm/lvm.conf" = lib.mkForce {
              source = ./lvm.conf;
              mode = "0600";
            };
          };

          services.udev = {
            extraRules = udevRules;
            packages = udevPackages;
          };
        };
    }
    ."${moduleContext}";
}

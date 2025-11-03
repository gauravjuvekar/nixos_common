{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.etc = {
    "lvm/lvm.conf" = lib.mkForce {
      source = ./files/lvm.conf;
      mode = "0600";
    };
  };

  services.udev = {
    extraRules = ''
      ENV{LVM_PVSCAN_ON_LVS}="1"
    '';
    packages = [
      (pkgs.writeTextFile {
        name = "my-lvm-initrd-udev-rules";
        destination = "/etc/udev/rules.d/10-local.rules";
        text = config.services.udev.extraRules;
      })
    ];
  };
}

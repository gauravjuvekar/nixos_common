{ lib, ... }:
let
  # These are the existing GPT partition UUIDs, so disko's generated mounts
  # work immediately without creating labels or repartitioning the disk.
  pvUuids = [
    "42b9b38a-16b2-4aff-8768-b5391905f3a0"
    "703f851b-918b-4a7a-b2e8-c9db5243a207"
    "fc32feeb-a778-4aea-8612-49451d105e76"
    "88ff9b7b-3323-4a99-8144-cee4cddbec8b"
    "ff37bc94-a183-49b9-9887-2ce8f8632558"
    "8f381d11-af5d-4363-b449-e307a713c1ae"
    "245c1708-1778-46c0-9993-ae021feffc1a"
    "a89dd1dd-4d1c-4980-8217-ebadc8c9d4c4"
  ];
  btrfsOptions = [
    "ssd"
    "discard"
    "noatime"
  ];
in
{
  # Importing this module only generates mount/unlock configuration.
  # NEVER run disko's format/destroy scripts against the running system.
  # The SD card (firmware + raw unlock key) is intentionally not managed here.
  disko.devices = {
    disk.system = {
      type = "disk";
      device = "/dev/disk/by-id/ata-SAMSUNG_MZNLN256HAJQ-000L7_S3RZNX0M145839";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 1;
            size = "512M";
            type = "EF00";
            uuid = "1ae9e8fa-93c1-47c0-b6e0-3616031bdc79";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/esp";
            };
          };
          boot = {
            priority = 2;
            size = "4G";
            uuid = "238a5cbb-395f-4db3-8c84-b7990a39c710";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
            };
          };
        }
        // builtins.listToAttrs (
          lib.imap0 (i: uuid: {
            name = "pv${toString (i + 3)}";
            value = {
              priority = i + 3;
              inherit uuid;
              type = "8E00";
              # Bare numbers are 512-byte sectors in sgdisk; retain p10's
              # original extent, including the small unused tail of the disk.
              size = if i == 7 then "20916224" else "32G";
              content = {
                type = "lvm_pv";
                vg = "base";
              };
            };
          }) pvUuids
        );
      };
    };
    lvm_vg = {
      base = {
        type = "lvm_vg";
        lvs.crypt = {
          size = "100%FREE";
          content = {
            type = "luks";
            name = "crypt_pv";
            extraFormatArgs = [
              "--type"
              "luks2"
            ];
            settings = {
              # Reuse the enrolled 4096-byte key; never copy it to the store.
              keyFile = "/dev/disk/by-partuuid/95d810ca-03";
              keyFileOffset = 8388608;
              keyFileSize = 4096;
              keyFileTimeout = 30;
            };
            content = {
              type = "lvm_pv";
              vg = "nix_vg";
            };
          };
        };
      };
      nix_vg = {
        type = "lvm_vg";
        # Keep the remaining ~122 GiB unallocated, as on the running system.
        lvs = {
          swap = {
            size = "16G";
            content.type = "swap";
          };
          root = {
            size = "64G";
            content = {
              type = "btrfs";
              subvolumes."@root" = {
                mountpoint = "/";
                mountOptions = btrfsOptions;
              };
            };
          };
          home = {
            size = "32G";
            content = {
              type = "btrfs";
              subvolumes."@home" = {
                mountpoint = "/home";
                mountOptions = btrfsOptions;
              };
            };
          };
        };
      };
    };
  };
}

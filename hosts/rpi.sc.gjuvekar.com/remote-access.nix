{ config, ... }:
let
  lanMac = "dc:a6:32:bb:35:08";
  lanName = "enabcm6e4ei0";
in
{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICW38PaCVme5Kic109sI0ir5U2ZvzXAbI0Qpt5Y67k92 gaurav@dt.sc.gjuvekar.com"
  ];
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Keep the existing wired interface name across systemd upgrades.
  systemd.network.links."10-rpi-lan" = {
    matchConfig.MACAddress = lanMac;
    linkConfig = {
      Name = lanName;
      NamePolicy = "";
    };
  };
  systemd.network.networks."10-rpi-lan" = {
    matchConfig.MACAddress = lanMac;
    networkConfig.DHCP = "yes";
    # Preserve the existing DHCP client identity and machine-id on upgrade.
  };

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      extraConfig = ''
        PermitRootLogin prohibit-password
        PubkeyAuthentication yes
      '';
      # Generate on the Pi before installing this generation (see README).
      # A string path keeps this separate recovery identity out of the store.
      hostKeys = [ "/var/lib/initrd-ssh/ssh_host_ed25519_key" ];
    };
  };
  boot.initrd.systemd.network = {
    enable = true;
    links."10-rpi-lan" = config.systemd.network.links."10-rpi-lan";
    networks."10-rpi-lan" = {
      matchConfig.MACAddress = lanMac;
      # Recovery must also work if the DHCP server is unavailable.
      # Reserve this existing address for lanMac on the router before reboot.
      address = [ "192.168.1.64/24" ];
      routes = [ { Gateway = "192.168.1.254"; } ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
      };
    };
  };
}

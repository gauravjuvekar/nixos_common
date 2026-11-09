{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-layout.nix
    ./remote-access.nix
    ./ingress.nix
    ./kanidm.nix
    ./ddns.nix
    ./gcloud-service-account-keys.nix
    ./home-assistant.nix
    ./iot-network.nix
  ];

  hostinfo = {
    isServer = true;
    isLaptop = false;
    hostname = "rpi";
    domainname = "sc.gjuvekar.com";
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPtEyOzw78nPAFZAE+mqNB4/SyEBV6DSy8+s2Gzuf1++ root@rpi";

  networking = {
    networkmanager.enable = false;
    useNetworkd = true;
    # Configure the wired interface explicitly in remote-access.nix.
    useDHCP = false;
    firewall.enable = true;
    nftables.enable = true;
  };
  systemd.network.enable = true;

  rpi.iot.internetAllowedMacs = [
    "94:45:60:6c:8b:36"
    "68:c6:ac:09:e0:c0" # lt2
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  users.mutableUsers = false;

  environment.systemPackages = with pkgs; [
    cryptsetup
    gitMinimal
    nix-output-monitor
    screen
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.copySystemConfiguration = false;

  # Preserve the original installation's state defaults across the upgrade.
  system.stateVersion = "23.11";
}

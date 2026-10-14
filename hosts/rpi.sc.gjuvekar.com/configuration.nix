{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-layout.nix
    ./remote-access.nix
  ];

  networking = {
    hostName = "rpi";
    domain = "sc.gjuvekar.com";
    networkmanager.enable = false;
    useNetworkd = true;
    # Configure the wired interface explicitly in remote-access.nix.
    useDHCP = false;
    firewall.enable = true;
    nftables.enable = true;
  };
  systemd.network.enable = true;

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

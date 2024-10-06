{ ... }:
{
  imports =
    [
      ./base_boot.nix
      ./base_etc.nix
      ./base_packages.nix
    ];

  nix.extraOptions =
    ''
      extra-experimental-features = flakes
      extra-experimental-features = nix-command
    '';

    systemd =
      {
        slices."nix-daemon".sliceConfig =
          {
            ManagedOOMMemoryPressure = "kill";
            ManagedOOMMemmoryPressureLimit = "90%";
          };

        services."nix-daemon".serviceConfig =
          {
            Slice = "nix-daemon.slice";
            OOMScoreAdjust = 1000;
          };
      };
}

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
      let
        systemd_config_str = ''
            StatusUnitFormat=combined
        '';
      in
      {
        extraConfig = systemd_config_str;
        user.extraConfig = systemd_config_str;

        slices."nix-daemon".sliceConfig =
          {
            ManagedOOMMemoryPressure = "kill";
            ManagedOOMMemoryPressureLimit = "90%";
          };

        services."nix-daemon".serviceConfig =
          {
            Slice = "nix-daemon.slice";
            OOMScoreAdjust = 1000;
          };
      };
}

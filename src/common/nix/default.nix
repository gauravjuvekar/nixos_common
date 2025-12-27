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
      "nixos-system" = {
        environment.systemPackages = lib.lists.optionals hostinfo.isLocalInteractive [
          pkgs.nh
          pkgs.nix-du
          pkgs.nix-output-monitor
          pkgs.nix-tree
        ];

        nix.extraOptions = ''
          extra-experimental-features = flakes
          extra-experimental-features = nix-command
        '';

        systemd = {
          slices."nix-daemon".sliceConfig = {
            ManagedOOMMemoryPressure = "kill";
            ManagedOOMMemoryPressureLimit = "90%";
          };

          services."nix-daemon".serviceConfig = {
            Slice = "nix-daemon.slice";
            OOMScoreAdjust = 1000;
          };
        };
      };
    }
    ."${moduleContext}";
}

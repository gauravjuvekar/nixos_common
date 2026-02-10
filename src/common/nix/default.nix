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

        services.nix-serve = lib.mkIf (hostinfo.fqdn == "dt.sc.gjuvekar.com") {
          enable = true;
          openFirewall = true;
          secretKeyFile = config.age.secrets.nix-binary-cache-priv-key.path;
        };

        nix.settings.trusted-public-keys = lib.mkIf (hostinfo.fqdn != "dt.sc.gjuvekar.com") [
          "dt.sc.gjuvekar.com:tXsxZ9VnwJl37+bx/j93c1krr7C7P2MXcidhvi4+V5I="
        ];

        age.secrets = lib.mkIf (hostinfo.fqdn == "dt.sc.gjuvekar.com") {
          nix-binary-cache-priv-key.rekeyFile = ../../../keys/secrets/nix-binary-cache-priv-key-dt.sc.gjuvekar.com.age;
        };
      };
    }
    ."${moduleContext}";
}

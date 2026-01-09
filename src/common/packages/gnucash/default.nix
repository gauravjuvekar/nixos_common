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

  domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
in
{
  config =
    lib.mkIf (domain_is_personal && hostinfo.isLocalGraphical)
      {
        "home-manager" = {
          home.packages = [
            pkgs.gnucash
          ];

          systemd.user.mounts = {
            "home-${config.home.username}-mnt-gnucash_readonly" = {
              Unit = {
                Description = "Read only mount of gnucash for libreoffice base odbc connector";
              };
              Mount =
                let
                  pkg_list = [
                    pkgs.bindfs
                    pkgs.coreutils
                    pkgs.findutils
                    pkgs.gnugrep
                    pkgs.gnused
                  ];
                  path = "${lib.makeBinPath pkg_list}:${lib.makeSearchPathOutput "bin" "sbin" pkg_list}";
                in
                {
                  What = "%h/Documents/finances/gnucash";
                  Where = "/home/${config.home.username}/mnt/gnucash_readonly";
                  Type = "fuse.bindfs";
                  Options = "ro,x-gvfs-hide";
                  Environment = "PATH=${path}";
                };
              Install = {
                WantedBy = [ "default.target" ];
              };
            };
          };

          dconf.settings = {
            "org/gnucash/GnuCash" = {
              "general/auto-decimal-point" = false;
              "general/date-format" = 3; # ISO
              "general/show-account-color-tabs" = false;
            };
          };
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

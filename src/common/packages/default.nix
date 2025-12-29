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
      "home-manager" =
        let
          domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
        in
        {
          home.packages = lib.lists.flatten (
            lib.lists.optionals hostinfo.isLocalGraphical [
              (lib.lists.optional domain_is_personal pkgs.calibre)
              (lib.lists.optional domain_is_personal pkgs.digikam)
              pkgs.chromium
              pkgs.graphviz
              pkgs.libreoffice
              pkgs.mate.atril
              pkgs.mpv
              pkgs.obs-studio
              pkgs.pdfarranger
              pkgs.plantuml
              pkgs.qalculate-gtk
              pkgs.remmina
              pkgs.sioyek
              pkgs.smplayer
              pkgs.thunderbird
              pkgs.vlc
            ]
            ++ lib.lists.optionals hostinfo.isLocalInteractive [
              pkgs.ansible
              pkgs.ansible-lint
              pkgs.jsonschema
              pkgs.repgrep
              pkgs.socat
            ]
          );
        };

      "nixos-system" = {
        environment.systemPackages = [
          pkgs.curl
          pkgs.fd
          pkgs.tree
          pkgs.wget
        ];
      };
    }
    ."${moduleContext}";
}

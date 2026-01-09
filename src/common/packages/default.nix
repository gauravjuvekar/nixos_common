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
              pkgs.blueberry
              pkgs.chromium
              pkgs.graphviz
              pkgs.imagemagick
              pkgs.libreoffice
              pkgs.mate.atril
              pkgs.mpv
              pkgs.obs-studio
              pkgs.pandoc
              pkgs.pdfarranger
              pkgs.pdftk
              pkgs.plantuml
              pkgs.poppler-utils # pdftotext
              pkgs.qalculate-gtk
              pkgs.qpdf
              pkgs.remmina
              pkgs.showmethekey
              pkgs.sioyek
              pkgs.smplayer
              pkgs.thunderbird
              pkgs.vlc
            ]
            ++ lib.lists.optionals hostinfo.isLocalInteractive [
              pkgs.age
              pkgs.ansible
              pkgs.ansible-lint
              pkgs.bat
              pkgs.file
              pkgs.inetutils
              pkgs.inotify-tools
              pkgs.jaq
              pkgs.jnv
              pkgs.jq
              pkgs.jqp
              pkgs.jsonschema
              pkgs.libsecret
              pkgs.moreutils
              pkgs.openssl
              pkgs.rage
              pkgs.rsync
              pkgs.socat
              pkgs.step-cli
              pkgs.watchexec
              pkgs.watchlog
              pkgs.watchman
            ]
          );
        };

      "nixos-system" = {
        environment.systemPackages = [
          pkgs.curl
          pkgs.dig
          pkgs.fd
          pkgs.tree
          pkgs.wget
        ];
      };
    }
    ."${moduleContext}";
}

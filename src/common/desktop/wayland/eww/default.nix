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
    lib.mkIf hostinfo.isLocalGraphical
      {
        home-manager =
          let
            # GtkImage's symbolic icon sizes can select oversized theme assets.
            # Expose its pixel-size override so taskbar icons have a fixed size.
            eww = pkgs.eww.overrideAttrs (old: {
              # Compiling simplexpr with the pinned Rust compiler exhausts its default stack.
              RUST_MIN_STACK = "33554432";
              patches = (old.patches or [ ]) ++ [ ./image-pixel-size.patch ];
            });
            # Order controls the calendar rows and scroll cycle; the first zone is the default.
            timezones = [
              "America/Los_Angeles"
              "Asia/Kolkata"
              "America/New_York"
              "Asia/Taipei"
              "Etc/UTC"
            ];
            backendConfig = pkgs.writeText "bar-status.json" (builtins.toJSON { inherit timezones; });
            backend = pkgs.rustPlatform.buildRustPackage {
              pname = "bar-status";
              version = "0.1.0";
              src = ./backend;
              cargoLock.lockFile = ./backend/Cargo.lock;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postInstall = ''
                wrapProgram "$out/bin/bar-status" \
                  --prefix PATH : ${
                    lib.makeBinPath [
                      pkgs.coreutils
                      pkgs.wireplumber
                      pkgs.brightnessctl
                      pkgs.bluez
                      pkgs.systemd
                      eww
                    ]
                  }
              '';
              meta.mainProgram = "bar-status";
            };
            command = lib.escapeShellArgs [
              (lib.getExe backend)
              "--config"
              (toString backendConfig)
            ];
            soundSettings = pkgs.writeShellApplication {
              name = "cinnamon-sound-settings";
              runtimeInputs = [ pkgs.glib ];
              text = ''
                exec ${pkgs.cinnamon-common}/bin/cinnamon-settings sound
              '';
            };
          in
          {
            programs.eww = {
              enable = true;
              package = eww;
              systemd.enable = true;
              yuckConfig =
                builtins.replaceStrings
                  [
                    "@backend@"
                    "@blueman@"
                    "@sound@"
                    "@icons@"
                    "@laptop@"
                  ]
                  [
                    command
                    "${pkgs.blueman}/bin/blueman-manager"
                    (lib.getExe soundSettings)
                    "${./icons}"
                    (lib.boolToString hostinfo.isLaptop)
                  ]
                  (
                    lib.concatMapStringsSep "\n" builtins.readFile (
                      [ ./eww.yuck ] ++ lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "yuck") ./modules)
                    )
                  );
              scssConfig = builtins.readFile ./eww.scss;
            };
            xdg.configFile."autostart/blueman.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Blueman Applet
              Hidden=true
            '';
            # The manager starts the applet on demand; suppress its tray icon too.
            dconf.settings."org/blueman/general".plugin-list = [
              "!StatusIcon"
              "!ShowConnected"
            ];
            systemd.user.services = {
              eww.Service.Restart = "on-failure";
              # Open one panel per active Niri output and follow display hotplug.
              eww-panels = {
                Unit = {
                  Description = "Eww panels for Niri outputs";
                  Requires = [ "eww.service" ];
                  After = [
                    "eww.service"
                    config.wayland.systemd.target
                  ];
                  PartOf = [
                    "eww.service"
                    config.wayland.systemd.target
                  ];
                  BindsTo = [ config.wayland.systemd.target ];
                };
                Service = {
                  ExecStart = "${command} panels";
                  Restart = "on-failure";
                };
                Install.WantedBy = [ config.wayland.systemd.target ];
              };
              # Hypridle honors systemd idle inhibitors. This unit starts only on click.
              eww-idle-inhibitor = {
                Unit = {
                  Description = "Eww idle inhibitor";
                  PartOf = [
                    "eww.service"
                    config.wayland.systemd.target
                  ];
                  BindsTo = [ config.wayland.systemd.target ];
                  After = [ config.wayland.systemd.target ];
                };
                Service.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle --mode=block --who=Eww --why=User-requested ${pkgs.coreutils}/bin/sleep infinity";
              };
            };
          };
        nixos-system = { };
      }
      ."${moduleContext}";
}

{
  config,
  inputs,
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
    let
      domain_is_personal = lib.strings.hasSuffix ".gjuvekar.com" hostinfo.domainname;
      fsaction_pkg = inputs.fsaction.outputs.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      "home-manager" = lib.mkIf (domain_is_personal && hostinfo.isLocalGraphical) {
        home.packages = [
          fsaction_pkg
          pkgs.poppler-utils # pdftotext
        ];
        systemd.user.services = {
          "fsaction@" = {
            Unit = {
              Description = "Watch %f for file changes and run %f/.fsaction";
            };
            Service = {
              Type = "exec";
              ExecStart = "${fsaction_pkg}/bin/fsaction \"%f\"";
            };
          };
        };
      };

      "nixos-system" = {
      };
    }
    ."${moduleContext}";
}

{
  inputs,
  pkgs,
  ...
}:
let
  fsaction_pkg = inputs.fsaction.outputs.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
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
}

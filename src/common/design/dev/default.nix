{
  config,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  usageinfo =
    {
      home-manager = osConfig.usageinfo;
      nixos-system = config.usageinfo;
    }
    ."${moduleContext}";
in
{
  imports = lib.fileset.toList (
    lib.fileset.fileFilter (f: (lib.strings.hasSuffix ".nix" f.name) && (f.name != "default.nix")) ./.
  );

  config =
    {
      "home-manager" = {
        home.packages = [
          (pkgs.writeShellApplication {
            name = "mv_versioned";
            text = builtins.readFile ./myapps/mv_versioned;
          })
        ]
        ++ lib.lists.optionals (usageinfo.devLangs != [ ]) [
          pkgs.lspmux
        ]
        ++ lib.lists.optionals (builtins.any (x: x == "cxx" || x == "rust") usageinfo.devLangs) [
          pkgs.gdb
        ];
      };

      "nixos-system" = { };
    }
    ."${moduleContext}";
}

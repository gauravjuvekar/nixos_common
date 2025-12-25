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
  config =
    {
      "home-manager" = {
        home.packages = lib.lists.optionals (builtins.elem "cxx" usageinfo.devLangs) [
          (lib.hiPrio pkgs.gcc) # HOLY SHIT, Clang is broken GH 277564, 153759, 147342
          pkgs.clang
          pkgs.clang-tools
          pkgs.compiledb
          pkgs.gnumake
          pkgs.llvmPackages.bintools
          pkgs.llvmPackages.libcxxStdenv
        ];

        home.shellAliases = {
          "m" = "make";
        };
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

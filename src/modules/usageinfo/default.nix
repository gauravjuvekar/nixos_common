{ lib, ... }:
{
  options.usageinfo = {
    devLangs = lib.mkOption {
      description = "Dev langs supported";
      type = lib.types.listOf (
        lib.types.enum [
          "cxx"
          "nix"
          "python"
          "rust"
        ]
      );
      default = [ ];
    };

    devTools = lib.mkOption {
      description = "Dev tools supported";
      type = lib.types.listOf (
        lib.types.enum [
          "binary"
          "containers"
          "db"
          "memory"
          "perf"
        ]
      );
      default = [ ];
    };

    cadTools = lib.mkOption {
      description = "CAD tools supported";
      type = lib.types.listOf (
        lib.types.enum [
          "2d"
          "3d"
          "gis"
          "eda"
        ]
      );
      default = [ ];
    };
  };
}

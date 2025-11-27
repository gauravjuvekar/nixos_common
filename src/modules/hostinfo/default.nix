{ config, lib, ... }:
let
  cfg = config.hostinfo;
in
{
  options.hostinfo = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      description = "Is laptop?";
    };
    isLocalGraphical = lib.mkOption {
      type = lib.types.bool;
      description = "Has local graphical stack; implies isInteractive and isGrapical";
      default = cfg.isLaptop;
    };
    isLocalInteractive = lib.mkOption {
      type = lib.types.bool;
      description = "Has local interactive terminal (keyboard); implies isInteractive";
      default = cfg.isLocalGraphical;
    };
    isGraphical = lib.mkOption {
      type = lib.types.bool;
      description = "Has remote / local graphical stack; implies isInteractive";
      default = cfg.isLocalGraphical;
    };
  };
}

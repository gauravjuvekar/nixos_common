{
  inputs,
  cell,
}:
let
  inherit (inputs.nixpkgs) lib;
  cfg = cell.hostinfo.config.hostinfo;
in
{
  options.hostinfo = {
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      description = "Is laptop?";
    };
    isInteractive = lib.mkOption {
      type = lib.types.bool;
      description = "Remote / local interactive vs server / container";
    };
    isLocalInteractive = lib.mkOption {
      type = lib.types.bool;
      description = "Has local interactive terminal (keyboard); implies isInteractive";
    };
    isGraphical = lib.mkOption {
      type = lib.types.bool;
      description = "Has remote / local graphical stack; implies isInteractive";
    };
    isLocalGraphical = lib.mkOption {
      type = lib.types.bool;
      description = "Has local graphical stack; implies isInteractive and isGrapical";
    };
  };

  config.hostinfo = {
    isLaptop = lib.mkDefault true;
    isLocalGraphical = lib.mkDefault cfg.isLaptop;
    isLocalInteractive = lib.mkDefault (
      if !(lib.isOption cfg.isLocalGraphical) then cfg.isLocalGraphical else false
    );
    isGraphical = lib.mkDefault cfg.isLocalGraphical;
    isInteractive = lib.mkDefault (cfg.isLocalInteractive == true || cfg.isGraphical == true);
  };
}

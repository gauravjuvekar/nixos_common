{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "cm";
      runtimeInputs = [
        pkgs.git
      ];
      text = builtins.readFile ./cm;
    })
    (pkgs.writeShellApplication {
      name = "cam";
      runtimeInputs = [
        pkgs.git
      ];
      text = builtins.readFile ./cam;
    })
    (pkgs.writeShellApplication {
      name = "cum";
      runtimeInputs = [
        pkgs.git
      ];
      text = builtins.readFile ./cum;
    })
    (pkgs.writeShellApplication {
      name = "cuam";
      runtimeInputs = [
        pkgs.git
      ];
      text = builtins.readFile ./cuam;
    })
    (pkgs.writeShellApplication {
      name = "g-mirror-except";
      runtimeInputs = [
        pkgs.git
        pkgs.ripgrep
      ];
      text = builtins.readFile ./g-mirror-except;
    })
    (pkgs.writeShellApplication {
      name = "g-bp";
      runtimeInputs = [
        pkgs.git
        pkgs.ripgrep
      ];
      text = builtins.readFile ./g-bp;
    })
    (pkgs.writeShellApplication {
      name = "g-clean-untracked";
      runtimeInputs = [
        pkgs.git
        pkgs.parallel
        pkgs.ripgrep
      ];
      text = builtins.readFile ./g-clean-untracked;
    })
    (pkgs.writeShellApplication {
      name = "mv_versioned";
      text = builtins.readFile ./mv_versioned;
    })
  ];
}

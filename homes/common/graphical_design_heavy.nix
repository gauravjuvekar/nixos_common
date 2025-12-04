{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./graphical_design_lite.nix
  ];

  home.packages = with pkgs; [
    blender
    freecad
    josm
    # kicad # broken
    openscad
    qgis
  ];
}

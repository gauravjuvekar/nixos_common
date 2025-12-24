{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blender
    freecad
    josm
    # kicad # broken
    openscad
    qgis
  ];
}

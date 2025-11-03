{
  droid-sans-mono-dotted,
  pkgs,
  ...
}:
{
  fonts.fontconfig.enable = true;
  home.packages =
    with pkgs;
    [
      cantarell-fonts
      # corefonts
      dejavu_fonts
      droid-sans-mono-dotted.droid-sans-mono-dotted-nerdfont
      gyre-fonts
      liberation_ttf
      libertine
      monaspace
      noto-fonts
      open-fonts
      proggyfonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}

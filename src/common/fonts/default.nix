{
  config,
  inputs,
  lib,
  moduleContext,
  osConfig ? null,
  pkgs,
  ...
}:
let
  hostinfo =
    {
      home-manager = osConfig.hostinfo;
      nixos-system = config.hostinfo;
    }
    ."${moduleContext}";
in
{
  config =
    lib.mkIf hostinfo.isLocalInteractive
      {
        "home-manager" = {
          fonts.fontconfig.enable = true;

          home.packages = lib.lists.flatten [
            pkgs.nerd-fonts.symbols-only
            (inputs.droid-sans-mono-dotted.outputs.packages.${pkgs.stdenv.hostPlatform.system}.droid-sans-mono-dotted-nerdfont
            )
            (inputs.droid-sans-mono-dotted.outputs.packages.${pkgs.stdenv.hostPlatform.system}.droid-sans-mono-slashed-nerdfont
            )
            (lib.lists.optional hostinfo.isLocalGraphical pkgs.gnome-font-viewer)
            pkgs.cantarell-fonts
            # pkgs.corefonts
            pkgs.dejavu_fonts
            pkgs.fira-code
            pkgs.gyre-fonts
            pkgs.inconsolata
            pkgs.liberation_ttf
            pkgs.libertine
            pkgs.monaspace.frozen
            pkgs.monaspace.static
            pkgs.monaspace.variable
            pkgs.noto-fonts
            pkgs.open-fonts
            pkgs.proggyfonts
            pkgs.ubuntu-classic
          ];
        };

        "nixos-system" = {
        };
      }
      ."${moduleContext}";
}

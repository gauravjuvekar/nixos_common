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
        home.packages = lib.lists.optionals (builtins.elem "rust" usageinfo.devLangs) [
          pkgs.cargo
          pkgs.cargo-audit
          pkgs.cargo-binutils
          pkgs.cargo-bump
          pkgs.cargo-depgraph
          pkgs.cargo-edit
          pkgs.cargo-hack
          pkgs.cargo-lock
          pkgs.cargo-outdated
          pkgs.cargo-play
          pkgs.cargo-sort
          pkgs.cargo-vet
          pkgs.cargo-watch
          pkgs.clippy
          pkgs.rust-analyzer
          pkgs.rustc
          pkgs.rustfmt
          pkgs.wasm-bindgen-cli
        ];

        xdg.configFile."rustfmt/rustfmt".text = ''
          max_width: 80
        '';
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

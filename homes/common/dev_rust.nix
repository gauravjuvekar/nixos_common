{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    cargo-audit
    cargo-binutils
    cargo-depgraph
    cargo-flamegraph
    cargo-lock
    cargo-play
    cargo-sort
    cargo-vet
    cargo-watch
    clippy
    ra-multiplex
    rust-analyzer
    rustc
    rustfmt
    wasm-bindgen-cli
  ];

  xdg.configFile."rustfmt/rustfmt".text = ''
    max_width: 80
  '';
}

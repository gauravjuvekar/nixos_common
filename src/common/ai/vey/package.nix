{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  capnproto,
  openssl,
  c-ares,
}:
rustPlatform.buildRustPackage {
  pname = "vey-proxy";
  version = "1.14.3";

  src = fetchFromGitHub {
    owner = "VEY-OSS";
    repo = "vey";
    tag = "vey-proxy-v1.14.3";
    hash = "sha256-WmF8c6elJlLHxh7QTljPflb6/sytAlelN1UNl3FHvQg=";
  };
  patches = [ ./socket-activation.patch ];
  cargoPatches = [ ./systemd-notify.patch ];

  cargoHash = "sha256-Dt0VeyWfH7nHOUlzrhoW/CMsLPy9b4j6DGrvjM4TKGY=";
  cargoBuildFlags = [
    "-p"
    "vey-proxy"
  ];
  cargoTestFlags = [
    "-p"
    "vey-proxy"
  ];
  buildNoDefaultFeatures = true;
  buildFeatures = [
    "c-ares"
    "rustls-ring"
  ];

  nativeBuildInputs = [
    pkg-config
    capnproto
  ];
  buildInputs = [
    openssl
    c-ares
  ];

  meta = {
    description = "Forward proxy with domain and egress access controls";
    homepage = "https://github.com/VEY-OSS/vey";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "vey-proxy";
  };
}

{ pkgs }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    pam_u2f
    yubikey-manager
  ];

  shellHook = ''
    export PAMU2FCFG_ORIGIN="pam://$(${pkgs.inetutils}/bin/hostname -f)"
  '';
}

{ ... }:
{
  imports = [
    ./networking.nix
    ./networking_personal.nix
  ];

  programs.fuse.userAllowOther = true;
}

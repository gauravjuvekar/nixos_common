{ ... }:
{
  imports = [
    ./networking_personal.nix
  ];

  programs.fuse.userAllowOther = true;
}

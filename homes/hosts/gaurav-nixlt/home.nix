{ ... }:
{
  imports = [
    ../../common/base.nix
    ../../common/dev_cxx.nix
    ../../common/dev_lite.nix
    ../../common/dev_rust.nix
    ../../common/fonts.nix
    ../../common/graphical.nix
    ../../common/graphical_apps.nix
    ../../common/graphical_design_lite.nix
    ../../common/graphical_dev.nix
    ../../common/graphical_docs.nix
    ../../common/graphical_gjuvekar-com.nix
    ../../common/graphical_yubikey.nix
    ../../common/interactive.nix
    ../../common/interactive_docs.nix
    ../../common/interactive_gjuvekar-com.nix
    ../../common/interactive_yubikey.nix
    ../../common/laptop.nix
    ../../common/user_gjuvekar-com.nix
  ];

  fqdn = "gaurav-lt.roam.gjuvekar.com";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.
}

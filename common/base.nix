{ ... }:
{
  imports = [
    ./base_boot.nix
    ./base_etc.nix
    ./base_packages.nix
  ];

  systemd =
    let
      systemd_config_str = ''
        StatusUnitFormat=combined
      '';
    in
    {
      settings.Manager = {
        StatusUnitFormat = "combined";
      };
      user.extraConfig = systemd_config_str;
    };
}

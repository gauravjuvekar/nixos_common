{ config, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      safe = {
        directory = [
          "/etc/nixos"
        ];
      };
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
      user = {
        name = config.fullname;
      };
    };
  };
}

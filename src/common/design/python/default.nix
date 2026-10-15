{
  config,
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
      "home-manager" = lib.mkIf hostinfo.isLocalInteractive {
        home.packages = lib.lists.optionals (builtins.elem "python" usageinfo.devLangs) [
          pkgs.isort
          pkgs.poetry
          pkgs.python3
          pkgs.uv
          pkgs.yapf
        ];
        home.shellAliases = {
          "p" = "python";
          "pdb" = "python -m pdb -c continue";
        };
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

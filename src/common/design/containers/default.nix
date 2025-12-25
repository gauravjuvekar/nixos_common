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
        home.packages = lib.lists.optionals (builtins.elem "containers" usageinfo.devTools) [
          pkgs.dive
          pkgs.kubectl
          pkgs.kubectl-validate
          pkgs.kubectx
          pkgs.kubernetes-helm
          pkgs.podman
          pkgs.podman-tui
          pkgs.skopeo
        ];
        home.shellAliases = {
          "k" = "kubectl";
        };
      };
      "nixos-system" = { };
    }
    ."${moduleContext}";
}

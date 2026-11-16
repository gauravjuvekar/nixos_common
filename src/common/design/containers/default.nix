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
        home.packages = lib.lists.optionals (builtins.elem "containers" usageinfo.devTools) [
          pkgs.dive
          pkgs.kubectl
          (pkgs.kubectl-validate.overrideAttrs (old: {
            # bug: Vendored kube-openapi's error traversal hangs with Go's JSON v2.
            # https://github.com/kubernetes-sigs/kubectl-validate/pull/185
            env = (old.env or { }) // {
              GOEXPERIMENT = "nojsonv2";
            };
          }))
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

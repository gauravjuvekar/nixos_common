{ pkgs, ... }:
{
  home.packages = with pkgs; [
    dive
    kubectl
    kubectl-validate
    kubectx
    kubernetes-helm
    podman
    podman-tui
    skopeo
  ];

  home.shellAliases = {
    "k" = "kubectl";
  };
}

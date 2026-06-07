{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = true;

    autoDeployCharts = {
      argo-cd = {
        name = "argo-cd";
        repo = "https://argoproj.github.io/argo-helm";
        version = "9.2.4";
        hash = "sha256-af6AmXcaEiUygfsosoxB8hUso8UZsPQK/dCOgmBlCg0=";
      };
    };

    # Hier lesen wir die YAML-Datei einfach dynamisch ein
    manifests.argocd-ingress = {
      target = "argocd-ingress.yaml";
      content = builtins.readFile ./argocd-ingress.yaml;
    };
  };
}
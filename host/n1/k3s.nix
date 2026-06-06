{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = true;
  };
  
  services.k3s.manifests.argocd-ingress = {
    content = builtins.readFile ./argocd-ingress.yaml;
  };

  services.k3s = {
    autoDeployCharts = {
      argo-cd = {
        name = "argo-cd";
        repo = "https://argoproj.github.io/argo-helm";
        version = "9.2.4";
        hash = "sha256-af6AmXcaEiUygfsosoxB8hUso8UZsPQK/dCOgmBlCg0=";
      };
    };
  };
}
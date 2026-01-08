{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = true;
  };
  
  services.k3s = {
    autoDeployCharts = {
      argo-cd = {
        name = "argo-cd";
        repo = "oci://ghcr.io/argoproj/argo-helm/argo-cd";
        version = "9.2.4";
        hash = "sha256-af6AmXcaEiUygfsosoxB8hUso8UZsPQK/dCOgmBlCg0=";
      };
    };
  };

}
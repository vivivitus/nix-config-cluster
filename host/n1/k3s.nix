{ config, ... }:

{
  imports = [
    ./bootstrap/argocd.nix
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = false;
  };
}
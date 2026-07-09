{ config, ... }:

{
  imports = [
    ./bootstrap/argocd.nix
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = false;
    extraFlags = [
      "--node-ip=10.0.2.50"
    ];
  };
}
{ config, ... }:

{
  imports = [
    ./bootstrap/argocd.nix
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = false;
    extraFlags = [
      "--tls-san" "10.0.2.50"
      "--tls-san" "2a02:168:5bab:1::50"
      "--node-ip=10.0.2.50,2a02:168:5bab:1::50"
      "--flannel-iface=enP4p65s0"
    ];
  };
}
{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    clusterInit = true;
  };
}
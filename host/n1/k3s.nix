{ config, ... }:

{
  services.k3s = {
    clusterInit = true;
  };
}
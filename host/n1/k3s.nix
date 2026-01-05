{ config, ... }:

{
  services.k3s = {
    cluster-init = true;
  };
}
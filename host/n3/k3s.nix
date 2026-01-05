{ config, ... }:

{
  imports = [
    ../common/k3s
  ];
  
  services.k3s = {
    serverAddr = "https://n1.lan:6443";
  };
}
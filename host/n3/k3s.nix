{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    serverAddr = "https://10.0.2.50:6443";
  };
}
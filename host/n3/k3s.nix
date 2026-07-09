{ config, ... }:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    serverAddr = "https://10.0.2.50:6443";
    extraFlags = [
      "--tls-san" "10.0.2.52"
      "--tls-san" "2a02:168:5bab:1::52"
      "--node-ip=10.0.2.52,2a02:168:5bab:1::52"
      "--flannel-iface=enP4p65s0"
    ];
  };
}
{ ipv4Address, ipv6Address, interface, ... }:

{
  imports = [
    ./bootstrap/argocd.nix
    ../common/k3s
  ];

  services.k3s = {
    #clusterInit = true;
    extraFlags = [
      "--tls-san" "${ipv4Address}"
      "--tls-san" "${ipv6Address}"
      "--node-ip=${ipv4Address},${ipv6Address}"
      "--flannel-iface=${interface}"
    ];
  };
}
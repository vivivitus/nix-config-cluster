{
  config,
  allHosts,
  ipv4Address,
  ipv6Address,
  interface,
  ...
}:

{
  imports = [
    ../common/k3s
  ];

  services.k3s = {
    serverAddr = "https://${allHosts.n1.ipv4Address}:6443";
    extraFlags = [
      "--tls-san"
      "${ipv4Address}"
      "--tls-san"
      "${ipv6Address}"
      "--node-ip=${ipv4Address},${ipv6Address}"
      "--flannel-iface=${interface}"
    ];
  };
}

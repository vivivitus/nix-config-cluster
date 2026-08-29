{
  ipv4Address,
  ipv6Address,
  interface,
  ...
}:

{
  imports = [
    ../common/k3s
  ];

  cluster.longhorn.storagePaths = [
    "/var/lib/storage0/longhorn"
  ];

  services.k3s = {
    clusterInit = true;

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

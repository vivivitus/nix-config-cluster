{ config, ... }:

{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      80
      443
    ];
    allowedUDPPorts = [
      8472 # k3s, flannel: required if using multi-node for inter-node networking
    ];
  };

  sops.secrets.cluster-token = {
    owner = config.users.users.root.name;
    group = config.users.users.root.name;
  };

  services.k3s = {
    enable = true;
    role = "server";
    token = config.sops.secrets.cluster-token.path;
    extraFlags = [ ];
  };
}
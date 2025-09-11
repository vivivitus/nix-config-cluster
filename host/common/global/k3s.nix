{ config, ... }:

{
  networking.firewall = {
    allowedTCPPorts = [
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
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
  };

  services.k3s = {
    autoDeployCharts.hello-world = {
      name = "hello-world";
      repo = "https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd";
      version = "0.1.0";
      hash = "sha256-U2XjNEWE82/Q3KbBvZLckXbtjsXugUbK6KdqT5kCccM=";
      # configure the chart values like you would do in values.yaml
      values = {
        replicaCount = 1;
        serviceAccount.create = false;
        servcie.port = 8080;
      };
    };
  };
}
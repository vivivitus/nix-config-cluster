{ config, pkgs, ... }:

{
  networking.firewall = {
    enable = true;
    trustedInterfaces = [
      "flannel.1"
      "cni0"
      ];

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

  sops.secrets = {
    cluster-token = {
      owner = config.users.users.root.name;
      group = config.users.users.root.name;
    };
    argocd-password = {
      owner = config.users.users.root.name;
      group = config.users.users.root.name;
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    package = pkgs.k3s_1_35;
    token = config.sops.secrets.cluster-token.path;
    extraFlags = [ 
      "--tls-san" "10.0.2.50" 
      "--tls-san" "10.0.2.51" 
      "--tls-san" "10.0.2.52"
      "--write-kubeconfig-mode" "644"
      # "--cluster-reset"
    ];
    manifests = {
      traefik-config = {
        target = "traefik-config.yaml";
        content = {
          apiVersion = "helm.cattle.io/v1";
          kind = "HelmChartConfig";
          metadata = {
            name = "traefik";
            namespace = "kube-system";
          };
          spec = {
            valuesContent = ''
              additionalArguments:
                - "--entryPoints.web.forwardedHeaders.insecure=true"
                - "--entryPoints.websecure.forwardedHeaders.insecure=true"
            '';
          };
        };
      };
    };
  };
}
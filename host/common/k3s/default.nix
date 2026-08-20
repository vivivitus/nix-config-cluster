{ config, pkgs, ... }:

let
  flannelCfg = pkgs.writeText "flannel-cfg.json" (builtins.toJSON {
    EnableIPv6 = true;
    Network = "10.42.0.0/16";
    IPv6Network = "fd42:ffee:9999::/48";
    Backend = {
      Type = "wireguard";
      Port = 51830;
    };
  });
in
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/rancher/k3s/server/cred"
      "/var/lib/rancher/k3s/server/tls"
      "/var/lib/rancher/k3s/server/db"
    ];
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [
      "flannel.1"
      "cni0"
    ];

    allowedTCPPorts = [
      6443 
      2379 
      2380 
      80
      443
    ];
    
    allowedUDPPorts = [
      8472 
      51830 # Hier direkt auf den neuen Port angepasst
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
      "--write-kubeconfig-mode" "644"
      "--flannel-backend=wireguard-native"
      "--flannel-conf" "${flannelCfg}"
      "--cluster-cidr=10.42.0.0/16,fd42:ffee:9999::/48"
      "--service-cidr=10.43.0.0/16,fd43:ffee:9999::/112"
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
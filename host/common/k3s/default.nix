{
  config,
  pkgs,
  clusterBootstrap,
  ...
}:

let
  flannelCfg = pkgs.writeText "flannel-cfg.json" (
    builtins.toJSON {
      EnableIPv6 = true;

      Network = "10.42.0.0/16";
      IPv6Network = "fd42:ffee:9999::/48";

      Backend = {
        Type = "wireguard";
        ListenPort = 51830;
        ListenPortV6 = 51830;
      };
    }
  );
in
{

  # imports = if clusterBootstrap then [ ./argocd.nix ] else [ ];
  environment.systemPackages = [
    pkgs.openiscsi
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
  ];

  networking.firewall = {
    enable = true;

    trustedInterfaces = [
      "cni0"
      "flannel-wg"
      "flannel-wg-v6"
    ];

    allowedTCPPorts = [
      6443
      2379
      2380
      80
      443
    ];

    allowedUDPPorts = [
      51830
    ];
  };

  sops.secrets.cluster-token = {
    owner = config.users.users.root.name;
    group = config.users.users.root.name;
  };

  services.k3s = {
    enable = false;
    role = "server";
    package = pkgs.k3s_1_35;

    token = config.sops.secrets.cluster-token.path;

    extraFlags = [
      "--write-kubeconfig-mode"
      "644"
      "--flannel-backend=wireguard-native"
      "--flannel-conf"
      "${flannelCfg}"
      "--cluster-cidr=10.42.0.0/16,fd42:ffee:9999::/48"
      "--service-cidr=10.43.0.0/16,fd43:ffee:9999::/112"
      "--flannel-ipv6-masq"
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

          spec.valuesContent = ''
            additionalArguments:
              - "--entryPoints.web.forwardedHeaders.insecure=true"
              - "--entryPoints.websecure.forwardedHeaders.insecure=true"

            resources:
              requests:
                cpu: "50m"
                memory: "50Mi"
              limits:
                cpu: "500m"
                memory: "250Mi"
          '';
        };
      };
    };
  };
}

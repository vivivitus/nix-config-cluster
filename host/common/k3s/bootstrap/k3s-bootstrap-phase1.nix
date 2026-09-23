{
  config,
  pkgs,
  clusterConfig,
  clusterTarget,
  ...
}:

let
  deployKeyPath = config.sops.secrets.cluster-deploy-key.path;
in
{
  systemd.services.k3s-bootstrap-phase1 = {
    description = "Bootstrap Argo CD on ${clusterTarget}";

    after = [
      "k3s.service"
      "sops-nix.service"
    ];

    requires = [
      "k3s.service"
    ];

    wants = [
      "sops-nix.service"
    ];

    wantedBy = [
      "multi-user.target"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      RuntimeDirectory = "k3s-bootstrap-phase1";
      RuntimeDirectoryMode = "0700";
    };

    path = with pkgs; [
      git
      kubectl
      openssh
    ];

    script = ''
      set -euo pipefail

      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh \
        -i ${deployKeyPath} \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new"

      repo="$RUNTIME_DIRECTORY/repo"

      echo "Waiting for Kubernetes API..."

      until kubectl get nodes >/dev/null 2>&1; do
        sleep 2
      done

      echo "Cloning cluster repository..."

      git clone \
        --depth 1 \
        --branch "${clusterConfig.gitBranch}" \
        "${clusterConfig.gitRepository}" \
        "$repo"

      echo "Bootstrapping Argo CD..."

      for attempt in $(seq 1 60); do
        if kubectl apply -k "$repo/k8s/bootstrap/argocd/"; then
          echo "Argo CD bootstrap completed."
          exit 0
        fi

        echo "Argo CD bootstrap not ready yet (attempt $attempt/60)."
        sleep 5
      done

      echo "Argo CD bootstrap failed." >&2
      exit 1
    '';
  };
}

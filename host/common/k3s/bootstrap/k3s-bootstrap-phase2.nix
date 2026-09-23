{
  config,
  pkgs,
  clusterConfig,
  clusterTarget,
  ...
}:

let
  deployKeyPath = config.sops.secrets.cluster-deploy-key.path;
  vaultTokenPath = config.sops.secrets.gitlab-vault-token.path;
  argocdTokenPath = config.sops.secrets.gitlab-argocd-token.path;
in
{
  systemd.services.k3s-bootstrap-phase2 = {
    description = "Complete GitOps bootstrap for ${clusterTarget}";

    requires = [
      "k3s-bootstrap-phase1.service"
    ];

    after = [
      "k3s-bootstrap-phase1.service"
      "sops-nix.service"
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

      RuntimeDirectory = "k3s-bootstrap-phase2";
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

      echo "Cloning cluster repository..."

      git clone \
        --depth 1 \
        --branch "${clusterConfig.gitBranch}" \
        "${clusterConfig.gitRepository}" \
        "$repo"

      echo "Creating Argo CD repository credentials..."

      kubectl create secret generic glab-pat-the-cluster \
        --namespace argocd \
        --from-file=sshPrivateKey="${deployKeyPath}" \
        --from-literal=url="${clusterConfig.gitRepository}" \
        --dry-run=client \
        -o yaml \
        | kubectl label \
            --local \
            -f - \
            argocd.argoproj.io/secret-type=repository \
            --overwrite \
            -o yaml \
        | kubectl apply -f -

      echo "Creating external-secrets namespace..."

      kubectl create namespace external-secrets \
        --dry-run=client \
        -o yaml \
        | kubectl apply -f -

      echo "Creating Vault credentials..."

      kubectl create secret generic glab-pat-vault \
        --namespace external-secrets \
        --from-file=token="${vaultTokenPath}" \
        --dry-run=client \
        -o yaml \
        | kubectl apply -f -

      rootApp="$repo/k8s/bootstrap/${clusterConfig.bootstrapRootApp}"

      if [ ! -f "$rootApp" ]; then
        echo "Root application does not exist: $rootApp" >&2
        exit 1
      fi

      echo "Applying root application..."

      for attempt in $(seq 1 60); do
        if kubectl apply -f "$rootApp"; then
          echo "Root application applied successfully."
          break
        fi

        if [ "$attempt" -eq 60 ]; then
          echo "Failed to apply root application." >&2
          exit 1
        fi

        echo "Root application not ready yet (attempt $attempt/60)."
        sleep 5
      done

      echo "Phase 2 completed successfully."
    '';
  };
}

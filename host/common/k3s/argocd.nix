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
  sops.secrets = {
    cluster-deploy-key = {
      path = "/etc/ssh/cluster-deploy-key";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    gitlab-vault-token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    gitlab-argocd-token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  systemd.services.k3s-bootstrap = {
    description = "Bootstrap ${clusterTarget} k3s cluster from ${clusterConfig.gitRepository}";

    after = [
      "network-online.target"
      "k3s.service"
      "sops-nix.service"
    ];

    requires = [
      "k3s.service"
    ];

    wants = [
      "network-online.target"
    ];

    wantedBy = [
      "multi-user.target"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      RuntimeDirectory = "k3s-bootstrap";
      RuntimeDirectoryMode = "0700";
    };

    path = with pkgs; [
      git
      kubectl
      coreutils
      gawk
      openssh
    ];

    script = ''
      set -Eeuo pipefail

      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      REPO_URL="${clusterConfig.gitRepository}"
      REPO_BRANCH="${clusterConfig.gitBranch}"
      ROOT_APP_FILE="${clusterConfig.bootstrapRootApp}"

      DEPLOY_KEY="${deployKeyPath}"
      VAULT_TOKEN_FILE="${vaultTokenPath}"
      ARGOCD_TOKEN_FILE="${argocdTokenPath}"

      WORKDIR="$RUNTIME_DIRECTORY"
      REPO_DIR="$WORKDIR/repo"

      log() {
        echo
        echo "============================================================"
        echo "==> $*"
        echo "============================================================"
      }

      die() {
        echo "ERROR: $*" >&2
        exit 1
      }

      cleanup() {
        if [[ -n "''${REPO_DIR:-}" && -d "$REPO_DIR" ]]; then
          rm -rf "$REPO_DIR"
        fi
      }

      trap cleanup EXIT

      ####################################################################
      # Preconditions
      ####################################################################

      log "Bootstrapping cluster target: ${clusterTarget}"

      [[ -f "$KUBECONFIG" ]] \
        || die "Kubeconfig does not exist: $KUBECONFIG"

      [[ -f "$DEPLOY_KEY" ]] \
        || die "Cluster deploy key does not exist: $DEPLOY_KEY"

      [[ -f "$VAULT_TOKEN_FILE" ]] \
        || die "GitLab vault token does not exist: $VAULT_TOKEN_FILE"

      [[ -f "$ARGOCD_TOKEN_FILE" ]] \
        || die "Argo CD GitLab token does not exist: $ARGOCD_TOKEN_FILE"

      [[ -n "$WORKDIR" ]] \
        || die "RUNTIME_DIRECTORY is not set"

      mkdir -p "$WORKDIR"

      ####################################################################
      # Wait for Kubernetes
      ####################################################################

      log "Waiting for Kubernetes API"

      for i in $(seq 1 60); do
        echo "Waiting for Kubernetes API (attempt $i/60)..."

        if kubectl \
          --request-timeout=5s \
          get --raw='/readyz' >/dev/null 2>&1 \
          && kubectl \
            --request-timeout=5s \
            get --raw='/openapi/v2' >/dev/null 2>&1
        then
          log "Kubernetes API and OpenAPI are ready"
          break
        fi

        if [ "$i" -eq 60 ]; then
          die "Kubernetes API did not become ready within 120 seconds"
        fi

        sleep 2
      done

      ####################################################################
      # Configure SSH for this service only
      ####################################################################

      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh \
        -i $DEPLOY_KEY \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new"

      ####################################################################
      # Clone cluster repository
      ####################################################################

      log "Cloning cluster repository"

      rm -rf "$REPO_DIR"

      git clone \
        --depth 1 \
        --branch "$REPO_BRANCH" \
        "$REPO_URL" \
        "$REPO_DIR"

      [[ -d "$REPO_DIR/.git" ]] \
        || die "Git repository was not cloned successfully"

      log "Repository cloned successfully"

      ####################################################################
      # Install Argo CD
      ####################################################################

      log "Installing Argo CD"

      kubectl --request-timeout=10s get --raw='/readyz'
      kubectl --request-timeout=10s get --raw='/openapi/v2' >/dev/null

      kubectl apply \
        --server-side \
        --force-conflicts \
        -k "$REPO_DIR/k8s/bootstrap/argocd"

      log "Waiting for Argo CD CRDs to be registered"

      until kubectl get crd applications.argoproj.io >/dev/null 2>&1; do
        sleep 2
      done

      log "Waiting for Argo CD components"

      kubectl rollout status \
        deployment/argocd-server \
        --namespace argocd \
        --timeout=10m

      kubectl rollout status \
        deployment/argocd-repo-server \
        --namespace argocd \
        --timeout=10m

      kubectl rollout status \
        statefulset/argocd-application-controller \
        --namespace argocd \
        --timeout=10m

      ####################################################################
      # Create Argo CD repository credential
      ####################################################################

      log "Creating Argo CD repository credential"

      kubectl create secret generic glab-pat-the-cluster \
        --namespace argocd \
        --from-literal=username="oauth2" \
        --from-file=password="$ARGOCD_TOKEN_FILE" \
        --from-literal=url="https://gitlab.com/kubernarnold/the-cluster.git" \
        --dry-run=client \
        -o yaml \
        | kubectl label \
            --local \
            -f - \
            argocd.argoproj.io/secret-type=repository \
            --overwrite \
            -o yaml \
        | kubectl apply -f -

      ####################################################################
      # Create initial ESO bootstrap secret
      ####################################################################

      log "Creating initial ESO bootstrap secret"

      kubectl create namespace external-secrets \
        --dry-run=client \
        -o yaml \
        | kubectl apply -f -

      kubectl create secret generic glab-pat-vault \
        --namespace external-secrets \
        --from-file=token="$VAULT_TOKEN_FILE" \
        --dry-run=client \
        -o yaml \
        | kubectl apply -f -

      ####################################################################
      # Apply root application
      ####################################################################

      ROOT_APP_PATH="$REPO_DIR/k8s/bootstrap/$ROOT_APP_FILE"

      [[ -f "$ROOT_APP_PATH" ]] \
        || die "Root application does not exist: $ROOT_APP_PATH"

      log "Applying root application: $ROOT_APP_FILE"

      kubectl apply -f "$ROOT_APP_PATH"

      ####################################################################
      # Wait for root application
      ####################################################################

      log "Waiting for root-app to be created"

      until kubectl get application root-app \
        --namespace argocd \
        >/dev/null 2>&1; do

        sleep 2
      done

      log "root-app created"

      ####################################################################
      # Restart Argo CD server
      #
      # Required because argocd-cmd-params-cm is installed as part of the
      # self-managed Argo CD application and the server must pick up the
      # updated command parameters.
      ####################################################################

      log "Restarting Argo CD server"

      kubectl rollout restart \
        deployment/argocd-server \
        --namespace argocd

      kubectl rollout status \
        deployment/argocd-server \
        --namespace argocd \
        --timeout=5m

      ####################################################################
      # Done
      ####################################################################

      log "Bootstrap completed successfully"

      kubectl get applications \
        --namespace argocd \
        || true
    '';
  };
}

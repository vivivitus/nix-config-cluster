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
      "k3s.service"
      "k3s-bootstrap-phase1.service"
    ];

    after = [
      "k3s.service"
      "k3s-bootstrap-phase1.service"
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

      ##################################################################
      # Preconditions
      ##################################################################

      log "PHASE 2: Completing bootstrap for ${clusterTarget}"

      [[ -f "$KUBECONFIG" ]] \
        || die "Kubeconfig does not exist: $KUBECONFIG"

      [[ -f "$DEPLOY_KEY" ]] \
        || die "Cluster deploy key does not exist: $DEPLOY_KEY"

      [[ -f "$VAULT_TOKEN_FILE" ]] \
        || die "GitLab vault token does not exist: $VAULT_TOKEN_FILE"

      [[ -f "$ARGOCD_TOKEN_FILE" ]] \
        || die "Argo CD GitLab token does not exist: $ARGOCD_TOKEN_FILE"

      ##################################################################
      # Verify Phase 1 state independently
      ##################################################################

      log "Verifying Argo CD API is ready"

      kubectl get crd applications.argoproj.io >/dev/null
      kubectl get crd applicationsets.argoproj.io >/dev/null
      kubectl get crd appprojects.argoproj.io >/dev/null

      kubectl api-resources \
        --api-group=argoproj.io \
        --no-headers \
        | awk '
            $NF == "Application"    { application=1 }
            $NF == "ApplicationSet" { applicationSet=1 }
            $NF == "AppProject"     { appProject=1 }
            END {
              exit !(application && applicationSet && appProject)
            }
          '

      log "Argo CD API is ready"

      ##################################################################
      # Configure SSH
      ##################################################################

      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh \
        -i $DEPLOY_KEY \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=accept-new"

      ##################################################################
      # Clone repository
      ##################################################################

      log "Cloning cluster repository"

      rm -rf "$REPO_DIR"

      git clone \
        --depth 1 \
        --branch "$REPO_BRANCH" \
        "$REPO_URL" \
        "$REPO_DIR"

      [[ -d "$REPO_DIR/.git" ]] \
        || die "Git repository was not cloned successfully"

      ##################################################################
      # Create AppProject
      ##################################################################

      log "Creating Argo CD bootstrap project"

      kubectl apply \
        --server-side \
        --force-conflicts \
        -f "$REPO_DIR/k8s/bootstrap/argocd/project.yaml"

      ##################################################################
      # Create Argo CD repository credential
      ##################################################################

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

      ##################################################################
      # Create ESO bootstrap secret
      ##################################################################

      log "Creating ESO bootstrap secret"

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

      ##################################################################
      # Apply root application
      ##################################################################

      ROOT_APP_PATH="$REPO_DIR/k8s/bootstrap/$ROOT_APP_FILE"

      [[ -f "$ROOT_APP_PATH" ]] \
        || die "Root application does not exist: $ROOT_APP_PATH"

      log "Applying root application: $ROOT_APP_FILE"

      kubectl apply -f "$ROOT_APP_PATH"

      ##################################################################
      # Wait for root application
      ##################################################################

      log "Waiting for root-app to be created"

      for i in $(seq 1 150); do
        if kubectl get application root-app \
          --namespace argocd \
          >/dev/null 2>&1
        then
          log "root-app created"
          break
        fi

        if [ "$i" -eq 150 ]; then
          die "root-app was not created within timeout"
        fi

        sleep 2
      done

      ##################################################################
      # Restart Argo CD server
      ##################################################################

      log "Restarting Argo CD server"

      kubectl rollout restart \
        deployment/argocd-server \
        --namespace argocd

      kubectl rollout status \
        deployment/argocd-server \
        --namespace argocd \
        --timeout=5m

      ##################################################################
      # Done
      ##################################################################

      log "PHASE 2 completed successfully"

      kubectl get applications \
        --namespace argocd \
        || true
    '';
  };
}

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
  };

  environment.etc."ssh/ssh_config.d/cluster-deploy-key.conf".text = ''
    Host gitlab.com-the-cluster
      HostName gitlab.com
      User git
      IdentityFile ${deployKeyPath}
      IdentitiesOnly yes
  '';

  systemd.services.k3s-bootstrap = {
    description = "Bootstrap ${clusterTarget} k3s cluster from ${clusterConfig.gitRepository}";

    after = [
      "network-online.target"
      "k3s.service"
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

      ######################################################################
      # Preconditions & API Check
      ######################################################################

      log "Bootstrapping cluster target: ${clusterTarget}"

      [[ -f "$KUBECONFIG" ]] || die "Kubeconfig does not exist: $KUBECONFIG"
      [[ -f "$VAULT_TOKEN_FILE" ]] || die "Vault token does not exist: $VAULT_TOKEN_FILE"

      log "Waiting for Kubernetes API"
      until kubectl get --raw=/readyz >/dev/null 2>&1; do
        sleep 2
      done
      log "Kubernetes API is ready"

      ######################################################################
      # 1. Install Argo CD via Remote Kustomize
      ######################################################################

      log "Installing Argo CD"
      KUSTOMIZE_TARGET="''${REPO_URL}//k8s/bootstrap/argocd?ref=''${REPO_BRANCH}"

      # Zweistufig anwenden, damit CRDs zuerst registriert werden
      kubectl apply --server-side --force-conflicts -k "$KUSTOMIZE_TARGET" || kubectl apply -k "$KUSTOMIZE_TARGET"

      log "Waiting for CRDs to be fully registered..."
      sleep 10

      log "Waiting for Argo CD components..."
      kubectl rollout status deployment/argocd-server --namespace argocd --timeout=10m
      kubectl rollout status deployment/argocd-repo-server --namespace argocd --timeout=10m
      kubectl rollout status statefulset/argocd-application-controller --namespace argocd --timeout=10m

      ######################################################################
      # 2. Create Bootstrap Secrets (ESO & Argo CD Repository)
      ######################################################################

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

      ######################################################################
      # 3. Apply Root Application
      ######################################################################

      log "Applying root application: $ROOT_APP_FILE"

      # Ins temporäre RuntimeDirectory wechseln
      cd "$RUNTIME_DIRECTORY" 2>/dev/null || cd "''${XDG_RUNTIME_DIR:-/run}/k3s-bootstrap"

      # Repo kurz flach auschecken (nutzt automatisch deine SSH-Config mit dem Deploy-Key!)
      git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" repo-temp

      # Root-App lokal anwenden
      kubectl apply -f "repo-temp/k8s/bootstrap/$ROOT_APP_FILE"

      # Aufräumen
      rm -rf repo-temp

      log "Waiting for root-app"
      until kubectl get application root-app --namespace argocd >/dev/null 2>&1; do
        sleep 2
      done

      ######################################################################
      # 4. Restart Argo CD to pick up ConfigMaps (wie in deiner README)
      ######################################################################

      log "Restarting Argo CD server to apply configurations"
      kubectl rollout restart deployment -n argocd argocd-server
      kubectl rollout status deployment -n argocd argocd-server --timeout=5m

      log "Bootstrap completed successfully!"
      kubectl get applications --namespace argocd || true
    '';
  };
}

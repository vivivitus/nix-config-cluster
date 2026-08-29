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

    before = [
      "k3s-bootstrap-phase2.service"
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
      coreutils
      gawk
      openssh
    ];

    script = ''
      set -Eeuo pipefail

      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      REPO_URL="${clusterConfig.gitRepository}"
      REPO_BRANCH="${clusterConfig.gitBranch}"

      DEPLOY_KEY="${deployKeyPath}"

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

      log "PHASE 1: Bootstrapping Argo CD on ${clusterTarget}"

      [[ -f "$KUBECONFIG" ]] \
        || die "Kubeconfig does not exist: $KUBECONFIG"

      [[ -f "$DEPLOY_KEY" ]] \
        || die "Cluster deploy key does not exist: $DEPLOY_KEY"

      ##################################################################
      # Wait for Kubernetes
      ##################################################################

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

      log "Repository cloned successfully"

      ##################################################################
      # Install Argo CD namespace
      ##################################################################

      log "Creating Argo CD namespace"

      kubectl apply \
        --server-side \
        --force-conflicts \
        -f "$REPO_DIR/k8s/bootstrap/argocd/namespace.yaml"

      ##################################################################
      # Install Argo CD core and CRDs
      ##################################################################

      log "Installing Argo CD core"

      kubectl apply \
        --server-side \
        --force-conflicts \
        -k "$REPO_DIR/k8s/manifests/base/argocd-core"

      ##################################################################
      # Wait for CRDs
      ##################################################################

      log "Waiting for Argo CD CRDs to be established"

      for crd in \
        applications.argoproj.io \
        applicationsets.argoproj.io \
        appprojects.argoproj.io
      do
        kubectl wait \
          --for=condition=Established \
          "crd/$crd" \
          --timeout=5m
      done

      ##################################################################
      # Wait for API discovery
      ##################################################################

      log "Waiting for Argo CD API resources"

      for i in $(seq 1 150); do
        if kubectl api-resources \
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
        then
          log "Argo CD API resources are ready"
          break
        fi

        if [ "$i" -eq 150 ]; then
          die "Argo CD API resources did not become available"
        fi

        sleep 2
      done

      ##################################################################
      # Wait for Argo CD components
      ##################################################################

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

      log "PHASE 1 completed successfully"
    '';
  };
}

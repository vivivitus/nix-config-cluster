{ pkgs, clusterTarget, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
  ];

  systemd.services.bootstrap-argocd = {
    description = "Bootstrap ArgoCD";

    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      kubectl
      coreutils
    ];

    script = ''
      set -euo pipefail

      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

      echo "Waiting for Kubernetes..."
      until kubectl get nodes >/dev/null 2>&1; do
        sleep 2
      done

      if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
        echo "ArgoCD already installed. Nothing to do."
        exit 0
      fi

      echo "Installing initial ArgoCD..."

      kubectl create namespace argocd

      kubectl apply \
        --server-side \
        -n argocd \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.2.12/manifests/install.yaml

      echo "Waiting for ArgoCD..."
      kubectl rollout status \
        deployment/argocd-server \
        -n argocd \
        --timeout=300s

      echo "Creating root application..."

      kubectl apply -f ${./argocd-root-app.yaml}

      echo "ArgoCD bootstrap complete."
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
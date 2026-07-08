{ pkgs, config, ... }: {

  environment.systemPackages = with pkgs; [
    kubernetes-helm
    kubectl
    apacheHttpd
  ];

  systemd.services.bootstrap-argocd = {
    description = "Automated ArgoCD bootstrapping with external script";
    
    after = [ "k3s.service" "sops-nix.service" ];
    wants = [ "k3s.service" "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [ kubectl coreutils gnugrep apacheHttpd ];

    # 'script' gehört HIERHIN, direkt in den Service
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Checking if ArgoCD already exists in the cluster..."

      # Wait for Kubernetes API server to become ready
      until kubectl get nodes >/dev/null 2>&1; do
        echo "Waiting for Kubernetes API server..."
        sleep 2
      done

      # Check if the 'argocd' namespace exists
      if kubectl get namespace argocd >/dev/null 2>&1; then
        echo "ArgoCD namespace already exists. Skipping bootstrap."
      else
        echo "ArgoCD not found. Starting full initialization..."
        
        # Create namespace
        kubectl create namespace argocd
        
        # 1. Install ArgoCD via Server-Side Apply
        kubectl apply --server-side=true -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # 2. Read initial admin password from SOPS path
        echo "Reading admin password from SOPS decrypted file..."
        if [ -f "$SOPS_PASSWORD_PATH" ]; then
          ARGOCD_ADMIN_PASSWORD=$(cat "$SOPS_PASSWORD_PATH" | tr -d '\n\r')
          PASSWORD_HASH=$(htpasswd -nbBC 10 "" "$ARGOCD_ADMIN_PASSWORD" | tr -d ':\n')
          
          echo "Setting initial admin password from SOPS..."
          kubectl patch secret argocd-secret -n argocd -p "{\"stringData\": {\"admin.password\": \"$PASSWORD_HASH\"}}"
        else
          echo "ERROR: SOPS secret file not found at $SOPS_PASSWORD_PATH" >&2
          exit 1
        fi

        # 3. Apply the external Ingress manifest
        echo "Applying ArgoCD Ingress configuration..."
        if [ -f "$INGRESS_MANIFEST_PATH" ]; then
          kubectl apply -f "$INGRESS_MANIFEST_PATH"
        else
          echo "WARNING: Ingress manifest not found at $INGRESS_MANIFEST_PATH. Skipping Ingress setup."
        fi
        
        echo "ArgoCD successfully installed, configured, and exposed!"
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [
        "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
        # Inject the dynamic paths into the script environment
        "SOPS_PASSWORD_PATH=${config.sops.secrets.argocd-password.path}"
        "INGRESS_MANIFEST_PATH=${./argocd-ingress.yaml}"
      ];
    };
  };
}
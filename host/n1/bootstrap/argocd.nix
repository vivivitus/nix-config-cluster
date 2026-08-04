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
        echo "Applying official ArgoCD manifests..."
        kubectl apply --server-side=true -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Warten, bis der Controller das Secret generiert hat
        echo "Waiting for argocd-secret to be created by the controller..."
        until kubectl get secret argocd-secret -n argocd >/dev/null 2>&1; do
          sleep 2
        done

        # 1.5 Insecure Modus konfigurieren & Server neu starten
        echo "Configuring ArgoCD to run in insecure mode..."
        kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'

        echo "Restarting argocd-server to apply configuration..."
        kubectl rollout restart deployment argocd-server -n argocd
        kubectl rollout status deployment argocd-server -n argocd --timeout=60s

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

        # 4. NEU: Die Root-Application injecten
        echo "Applying ArgoCD Root Application..."
        if [ -f "$ROOT_APP_MANIFEST_PATH" ]; then
          # Wir warten kurz, bis die ArgoCD CRDs wirklich komplett aktiv sind
          kubectl wait --for=condition=established --timeout=60s crd/applications.argoproj.io
          kubectl apply -f "$ROOT_APP_MANIFEST_PATH"
        else
          echo "WARNING: Root Application manifest not found at $ROOT_APP_MANIFEST_PATH."
        fi
        
        echo "ArgoCD successfully installed, configured, and synchronized with Git!"
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [
        "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
        "SOPS_PASSWORD_PATH=${config.sops.secrets.argocd-password.path}"
        "INGRESS_MANIFEST_PATH=${./argocd-ingress.yaml}"
        "ROOT_APP_MANIFEST_PATH=${./argocd-root-app.yaml}" # NEU: Pfad-Injektion
      ];
    };
  };
}
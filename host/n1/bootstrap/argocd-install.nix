script = ''
  #!/usr/bin/env bash
  # Strict error handling
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
    
    # 2. Read initial admin password from SOPS path (passed via env variable)
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

    # 3. Apply the external Ingress manifest (passed via env variable)
    echo "Applying ArgoCD Ingress configuration..."
    kubectl apply -f "$INGRESS_MANIFEST_PATH"
    
    echo "ArgoCD successfully installed, configured, and exposed via Ingress!"
  fi
''
#!/usr/bin/env bash
# deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"
EXTRA_FILES_DIR="/home/vivian/Documents/nixos-anywhere"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <profile-name>"
    echo "Example: $0 vbox"
    exit 1
fi

PROFILE_NAME="$1"

if ! [[ "$PROFILE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Invalid PROFILE_NAME: must contain only letters, numbers, underscores, or hyphens"
    exit 1
fi

PROFILE_FILE="$SCRIPT_DIR/profiles/${PROFILE_NAME}.sh"
if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "ERROR: Profile '$PROFILE_NAME' not found at $PROFILE_FILE"
    exit 1
fi

source "$PROFILE_FILE"

if ! [[ "$PROVIDER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Invalid PROVIDER: must contain only letters, numbers, underscores, or hyphens"
    exit 1
fi

PROVIDER_FILE="$SCRIPT_DIR/providers/${PROVIDER}.sh"
if [[ ! -f "$PROVIDER_FILE" ]]; then
    echo "ERROR: Provider implementation '$PROVIDER' not found at $PROVIDER_FILE"
    exit 1
fi

source "$PROVIDER_FILE"

echo "Starting deployment using profile: $PROFILE_NAME (Provider: $PROVIDER)"

# ISO bauen
echo "Building bootstrap ISO..."
nix build "${FLAKE_DIR}#nixosConfigurations.iso.config.system.build.isoImage" --out-link "${SCRIPT_DIR}/install-image"

ISO_PATH="$(find -L "${SCRIPT_DIR}/install-image" -type f -name '*.iso' -print -quit)"
if [[ -z "$ISO_PATH" ]]; then
    echo "ERROR: Could not find generated ISO."
    exit 1
fi

# Netzwerk & DHCP einrichten
echo "Configuring network..."
setup_network

# VMs erstellen
echo "Creating/configuring VMs..."
create_vms "$ISO_PATH"

# VMs starten
echo "Start VMs..."
start_vms

# Auf SSH warten
echo "Waiting for SSH..."
for i in "${!VMS_NAME[@]}"; do
    VM="${VMS_NAME[$i]}"
    IP="${VMS_IP[$i]}"
    until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$IP" true 2>/dev/null; do
        sleep 2
    done
    echo "${VM} ready."
done

# NixOS Deployment
echo "Deploying NixOS..."
mkdir -p "${SCRIPT_DIR}/deploy-log"
PIDS=()
for i in "${!VMS_NAME[@]}"; do
    VM="${VMS_NAME[$i]}"
    IP="${VMS_IP[$i]}"
    EXTRA_DIR="${VM%-vm}"

    (
        nix run github:nix-community/nixos-anywhere -- \
            --no-reboot \
            --extra-files "${EXTRA_FILES_DIR}/${EXTRA_DIR}" \
            --flake "${FLAKE_DIR}#${VM}" \
            "root@${IP}"
    ) >"${SCRIPT_DIR}/deploy-log/${VM}.log" 2>&1 &
    PIDS+=("$!:$VM")
done

FAILED=0
for item in "${PIDS[@]}"; do
    PID="${item%%:*}"
    VM="${item##*:}"
    if wait "$PID"; then
        echo "${VM}: success."
    else
        echo "${VM}: failed."
        FAILED=1
    fi
done

if [[ "$FAILED" -ne 0 ]]; then
    echo "ERROR: Deployment failed."
    exit 1
fi

# Finalisierung
echo "Finalizing VMs..."
finalize_vms
echo "Done."
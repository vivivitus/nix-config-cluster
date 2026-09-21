#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

BOOTSTRAP_KEY=".bootstrap/bootstrap-key"

EXTRA_FILES_DIR="./extra-files"
COMMON_EXTRA_FILES="${EXTRA_FILES_DIR}/common"

DEPLOY_LOG_DIR="deploy-log"

VMS_NAME=(
  "n1-vm"
  "n2-vm"
  "n3-vm"
)

VMS_IP=(
  "192.168.63.101"
  "192.168.63.102"
  "192.168.63.103"
)


echo
echo "========================================"
echo " NixOS deployment"
echo "========================================"
echo


if [[ ! -f "${BOOTSTRAP_KEY}" ]]; then
  echo "ERROR: Bootstrap SSH key not found:"
  echo "  ${BOOTSTRAP_KEY}"
  echo
  echo "Run deploy-vbox.sh first."
  exit 1
fi


if [[ ! -d "${COMMON_EXTRA_FILES}" ]]; then
  echo "ERROR: Common extra-files directory not found:"
  echo "  ${COMMON_EXTRA_FILES}"
  exit 1
fi


mkdir -p "${DEPLOY_LOG_DIR}"
rm -f "${DEPLOY_LOG_DIR}"/*.log


echo
echo "Starting nixos-anywhere deployments..."
echo


PIDS=()

for i in "${!VMS_NAME[@]}"; do
  VM="${VMS_NAME[$i]}"
  IP="${VMS_IP[$i]}"

  NODE="${VM%-vm}"

  NODE_EXTRA_FILES="${EXTRA_FILES_DIR}/${NODE}"
  LOG_FILE="${DEPLOY_LOG_DIR}/${VM}.log"

  if [[ ! -d "${NODE_EXTRA_FILES}" ]]; then
    echo "ERROR: Extra-files directory for ${VM} not found:"
    echo "  ${NODE_EXTRA_FILES}"
    exit 1
  fi

  echo "Starting ${VM} (${IP})..."
  echo "  Common: ${COMMON_EXTRA_FILES}"
  echo "  Node:   ${NODE_EXTRA_FILES}"
  echo "  Log:    ${LOG_FILE}"

  (
    nix run github:nix-community/nixos-anywhere -- \
      --extra-files "${COMMON_EXTRA_FILES}" \
      --extra-files "${NODE_EXTRA_FILES}" \
      --flake "..#${VM}" \
      --target-host "root@${IP}" \
      -i "${BOOTSTRAP_KEY}" \
      --ssh-option "BatchMode=yes" \
      --ssh-option "StrictHostKeyChecking=no" \
      --ssh-option "UserKnownHostsFile=/dev/null" \
      > "${LOG_FILE}" 2>&1
  ) &

  PIDS+=("$!")
done

echo
echo "Waiting for deployments..."
echo

FAILED=0

for i in "${!PIDS[@]}"; do
  VM="${VMS_NAME[$i]}"
  PID="${PIDS[$i]}"

  if wait "${PID}"; then
    echo "SUCCESS: ${VM}"
  else
    echo "FAILED: ${VM}"
    FAILED=1
  fi
done

echo

if [[ "${FAILED}" -ne 0 ]]; then
  echo "One or more deployments failed."
  echo
  echo "Logs:"
  ls -lh "${DEPLOY_LOG_DIR}"/*.log 2>/dev/null || true
  exit 1
fi

echo "All NixOS deployments completed successfully."
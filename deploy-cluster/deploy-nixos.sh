#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

BOOTSTRAP_KEY=".bootstrap/bootstrap-key"
EXTRA_FILES_DIR="./extra-files"
DEPLOY_LOG_DIR="deploy-log"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <host> <target-host>"
  exit 1
fi

HOST="$1"
TARGET_HOST="$2"
NODE="${HOST%-vm}"
NODE_EXTRA_FILES="${EXTRA_FILES_DIR}/${NODE}"
LOG_FILE="${DEPLOY_LOG_DIR}/${HOST}.log"

if [[ ! -f "${BOOTSTRAP_KEY}" ]]; then
  echo "ERROR: Bootstrap SSH key not found:"
  echo "  ${BOOTSTRAP_KEY}"
  exit 1
fi

if [[ ! -d "${NODE_EXTRA_FILES}" ]]; then
  echo "ERROR: Extra-files directory not found:"
  echo "  ${NODE_EXTRA_FILES}"
  exit 1
fi

mkdir -p "${DEPLOY_LOG_DIR}"

echo "Host: ${HOST}"
echo "Target: ${TARGET_HOST}"
echo "Extra files: ${NODE_EXTRA_FILES}"
echo "Log: ${LOG_FILE}"
echo

nix run github:nix-community/nixos-anywhere -- \
  --extra-files "${NODE_EXTRA_FILES}" \
  --flake "..#${HOST}" \
  --target-host "root@${TARGET_HOST}" \
  -i "${BOOTSTRAP_KEY}" \
  --ssh-option "BatchMode=yes" \
  --ssh-option "StrictHostKeyChecking=no" \
  --ssh-option "UserKnownHostsFile=/dev/null" \
  > "${LOG_FILE}" 2>&1

#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

ROOT_DIR="$(cd .. && pwd)"

TARGETS_FILE=".deploy-targets.json"


# ========================================
# Deployment targets
# ========================================

generate_targets() {
  echo "Generating deployment targets..."

  nix eval --json \
    "${ROOT_DIR}#deployTargets" \
    > "${TARGETS_FILE}"

  echo "Generated ${TARGETS_FILE}"
}


# ========================================
# Deploy single host
# ========================================

deploy_host() {
  local host="$1"
  local prepare_vm="${2:-true}"

  local ip
  local is_virtual_machine

  ip="$(
    jq -r --arg host "${host}" '
      .[$host].ipv4Address // empty
    ' "${TARGETS_FILE}"
  )"

  is_virtual_machine="$(
    jq -r --arg host "${host}" '
      .[$host].isVirtualMachine // empty
    ' "${TARGETS_FILE}"
  )"

  if [[ -z "${ip}" ]]; then
    echo "ERROR: Unknown deployment target: ${host}"
    exit 1
  fi

  if [[ "${is_virtual_machine}" == "true" && "${prepare_vm}" == "true" ]]; then
    ./deploy-vbox.sh "${host}"
  fi

  ./deploy-nixos.sh "${host}" "${ip}"
}

deploy_vm_stack() {
  local hosts

  hosts="$(
    jq -r '
      to_entries[]
      | select(.value.isVirtualMachine == true)
      | .key
    ' "${TARGETS_FILE}"
  )"

  if [[ -z "${hosts}" ]]; then
    echo "ERROR: No virtual machines defined."
    exit 1
  fi

  echo
  echo "========================================"
  echo " Building and deploying VM stack"
  echo "========================================"
  echo

  # deploy-vbox.sh handles the complete VM lifecycle:
  #
  #   1. Build all Disko images in parallel
  #   2. If all builds succeed:
  #      - remove existing VMs
  #      - create new VMs
  #      - start all VMs
  #
  # If any image build fails, existing VMs are left untouched.
  ./deploy-vbox.sh vm

  echo
  echo "========================================"
  echo " VM deployment completed"
  echo "========================================"
}


# ========================================
# Deploy
# ========================================

deploy() {
  local target="$1"

  if [[ "${target}" == "vm" ]]; then
    deploy_vm_stack
  else
    deploy_host "${target}"
  fi
}


# ========================================
# Clean
# ========================================

clean() {
  echo "Cleaning deployment state..."

  rm -rf \
    "${TARGETS_FILE}" \
    "deploy-log" \
    "result"

  echo "Deployment state cleaned."
}


# ========================================
# Main
# ========================================

case "${1:-}" in
  targets)
    generate_targets
    ;;

  deploy)
    if [[ $# -ne 2 ]]; then
      echo "Usage:"
      echo "  $0 deploy <host>"
      echo "  $0 deploy vm"
      exit 1
    fi

    generate_targets
    deploy "$2"
    ;;

  clean)
    clean
    ;;

  *)
    echo "Usage:"
    echo "  $0 deploy <host>"
    echo "  $0 deploy vm"
    echo "  $0 targets"
    echo "  $0 clean"
    exit 1
    ;;
esac
#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

ROOT_DIR="$(cd .. && pwd)"

TARGETS_FILE=".deploy-targets.json"

BOOTSTRAP_DIR=".bootstrap"
BOOTSTRAP_KEY="${BOOTSTRAP_DIR}/bootstrap-key"
BOOTSTRAP_PUBLIC_KEY="${BOOTSTRAP_DIR}/bootstrap-key.pub"


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
# Bootstrap SSH key
# ========================================

ensure_bootstrap_key() {
  mkdir -p "${BOOTSTRAP_DIR}"

  if [[ -f "${BOOTSTRAP_KEY}" && -f "${BOOTSTRAP_PUBLIC_KEY}" ]]; then
    echo "Reusing existing bootstrap SSH key:"
    echo "  ${BOOTSTRAP_KEY}"
    return
  fi

  echo "Creating bootstrap SSH key..."

  ssh-keygen \
    -q \
    -t ed25519 \
    -N "" \
    -f "${BOOTSTRAP_KEY}" \
    -C "nixos-vagrant-bootstrap"

  chmod 600 "${BOOTSTRAP_KEY}"
  chmod 644 "${BOOTSTRAP_PUBLIC_KEY}"
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


# ========================================
# Deploy complete VM stack
# ========================================

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

  ./deploy-vbox.sh vm

  local -a pids=()
  local host

  while IFS= read -r host; do
    deploy_host "${host}" false &
    pids+=("$!")
  done <<< "${hosts}"

  local status=0

  echo
  echo "========================================"
  echo " Waiting for deployments"
  echo "========================================"
  echo

  for pid in "${pids[@]}"; do
    if ! wait "${pid}"; then
      status=1
    fi
  done

  echo

  if [[ "${status}" -eq 0 ]]; then
    echo "========================================"
    echo " Deployment completed"
    echo "========================================"
  else
    echo "========================================"
    echo " Deployment failed"
    echo "========================================"
  fi

  echo

  return "${status}"
}

deploy() {
  local target="$1"

  if [[ "${target}" == "vm" ]]; then
    deploy_vm_stack
  else
    deploy_host "${target}"
  fi
}

clean() {
  echo "Cleaning deployment state..."

  rm -rf "${BOOTSTRAP_DIR}"
  rm -f "${TARGETS_FILE}"

  echo "Deployment state cleaned."
}

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

    ensure_bootstrap_key
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
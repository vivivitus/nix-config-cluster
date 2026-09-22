#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

BOOTSTRAP_DIR=".bootstrap"
BOOTSTRAP_KEY="${BOOTSTRAP_DIR}/bootstrap-key"
BOOTSTRAP_PUBLIC_KEY_FILE="$(pwd)/${BOOTSTRAP_DIR}/bootstrap-key.pub"

TARGETS_FILE=".deploy-targets.json"

BOX_NAME="nixos-vbox"
BOX_FILE="nixos-vbox.box"

WORKDIR=""

cleanup() {
  rm -rf "${WORKDIR:-}"
}

trap cleanup EXIT

if [[ $# -ne 1 ]]; then
  echo "Usage:"
  echo "  $0 <host>"
  echo "  $0 vm"
  exit 1
fi

TARGET="$1"

if [[ ! -f "${BOOTSTRAP_KEY}" || ! -f "${BOOTSTRAP_PUBLIC_KEY_FILE}" ]]; then
  echo "ERROR: Bootstrap SSH key not found."
  exit 1
fi

if [[ ! -f "${TARGETS_FILE}" ]]; then
  echo "ERROR: Deployment targets not found."
  exit 1
fi

if [[ "${TARGET}" != "vm" ]]; then
  IS_VIRTUAL_MACHINE="$(
    jq -r --arg host "${TARGET}" '
      .[$host].isVirtualMachine // empty
    ' "${TARGETS_FILE}"
  )"

  if [[ "${IS_VIRTUAL_MACHINE}" != "true" ]]; then
    echo "ERROR: Not a virtual machine target: ${TARGET}"
    exit 1
  fi
fi

echo
echo "========================================"
echo " Build VirtualBox image"
echo "========================================"
echo

export BOOTSTRAP_PUBLIC_KEY_FILE

OVA_PATH="$(
  nixos-rebuild \
    --impure \
    build-image \
    --image-variant virtualbox \
    --flake "..#vbox-vm" \
    --print-build-logs |
    tail -n 1
)"

echo
echo "OVA: ${OVA_PATH}"

echo
echo "========================================"
echo " Create Vagrant box"
echo "========================================"
echo

WORKDIR="$(mktemp -d)"

echo "Extracting OVA..."
tar -xf "${OVA_PATH}" -C "${WORKDIR}"

cat > "${WORKDIR}/metadata.json" <<'EOF'
{
  "provider": "virtualbox"
}
EOF

rm -f "${BOX_FILE}"

echo "Creating Vagrant box..."

(
  cd "${WORKDIR}"

  OVF_FILE="$(find . -maxdepth 1 -name '*.ovf' -print -quit)"

  if [[ -z "${OVF_FILE}" ]]; then
    echo "ERROR: No OVF file found"
    exit 1
  fi

  mv "${OVF_FILE}" box.ovf

  tar \
    -czf "${OLDPWD}/${BOX_FILE}" \
    metadata.json \
    box.ovf \
    *.vmdk
)

echo
echo "Created:"
ls -lh "${BOX_FILE}"

echo
echo "========================================"
echo " Update Vagrant box"
echo "========================================"
echo

if vagrant box list | grep -q "^${BOX_NAME} "; then
  echo "Removing old ${BOX_NAME}..."

  vagrant box remove \
    "${BOX_NAME}" \
    --all \
    --force
fi

vagrant box add \
  --name "${BOX_NAME}" \
  "${BOX_FILE}"

echo
echo "========================================"
echo " Start Vagrant environment"
echo "========================================"
echo

if [[ "${TARGET}" == "vm" ]]; then
  echo "Starting all virtual machines..."

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

  while IFS= read -r host; do
    echo "Destroying ${host}..."
    vagrant destroy "${host}" -f || true
  done <<< "${hosts}"

  pids=()

  while IFS= read -r host; do
    echo "Starting ${host}..."

    vagrant up "${host}" &
    pids+=("$!")
  done <<< "${hosts}"

  status=0

  for pid in "${pids[@]}"; do
    if ! wait "${pid}"; then
      status=1
    fi
  done

  if [[ "${status}" -ne 0 ]]; then
    echo "ERROR: One or more VMs failed to start."
    exit "${status}"
  fi

else
  echo "Starting ${TARGET}..."

  vagrant destroy "${TARGET}" -f || true
  vagrant up "${TARGET}"
fi
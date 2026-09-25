#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGETS_FILE="${SCRIPT_DIR}/.deploy-targets.json"
BRIDGE_SCRIPT="${SCRIPT_DIR}/bridge-interface.sh"
EXTRA_FILES_DIR="${SCRIPT_DIR}/extra-files"

if [[ $# -ne 1 ]]; then
  echo "Usage:"
  echo "  $0 vm"
  echo "  $0 <host>"
  exit 1
fi

TARGET="$1"

if [[ ! -f "${TARGETS_FILE}" ]]; then
  echo "ERROR: Deployment targets not found."
  echo "Run: ./deploy.sh targets"
  exit 1
fi

if [[ ! -x "${BRIDGE_SCRIPT}" ]]; then
  echo "ERROR: ${BRIDGE_SCRIPT} not found or not executable."
  exit 1
fi

BRIDGE_INTERFACE="$("${BRIDGE_SCRIPT}")"

if [[ -z "${BRIDGE_INTERFACE}" ]]; then
  echo "ERROR: Could not determine host bridge interface."
  exit 1
fi

echo "Using bridge interface: ${BRIDGE_INTERFACE}"

if [[ "${TARGET}" == "vm" ]]; then
  mapfile -t HOSTS < <(
    jq -r '
      to_entries[]
      | select(.value.isVirtualMachine == true)
      | .key
    ' "${TARGETS_FILE}"
  )
else
  IS_VIRTUAL_MACHINE="$(
    jq -r --arg host "${TARGET}" '
      .[$host].isVirtualMachine // empty
    ' "${TARGETS_FILE}"
  )"

  if [[ "${IS_VIRTUAL_MACHINE}" != "true" ]]; then
    echo "ERROR: Not a virtual machine target: ${TARGET}"
    exit 1
  fi

  HOSTS=("${TARGET}")
fi

if [[ "${#HOSTS[@]}" -eq 0 ]]; then
  echo "ERROR: No virtual machine targets found."
  exit 1
fi

echo
echo "VirtualBox targets:"
printf '  %s\n' "${HOSTS[@]}"

echo
echo "========================================"
echo " Building Disko image(s)"
echo "========================================"
echo

build_image() {
  local host="$1"

  local build_dir="${SCRIPT_DIR}/build-${host}"
  local key_host="${host%-vm}"
  local host_extra_files_dir="${EXTRA_FILES_DIR}/${key_host}"

  local ssh_key_priv="${host_extra_files_dir}/persist/etc/ssh/ssh_host_ed25519_key"
  local ssh_key_pub="${host_extra_files_dir}/persist/etc/ssh/ssh_host_ed25519_key.pub"

  if [[ ! -f "${ssh_key_priv}" ]]; then
    echo "ERROR: SSH private host key not found:"
    echo "  ${ssh_key_priv}"
    return 1
  fi

  if [[ ! -f "${ssh_key_pub}" ]]; then
    echo "ERROR: SSH public host key not found:"
    echo "  ${ssh_key_pub}"
    return 1
  fi

  local disko_args=(
    --post-format-files
    "${ssh_key_priv}"
    "/persist/etc/ssh/ssh_host_ed25519_key"

    --post-format-files
    "${ssh_key_pub}"
    "/persist/etc/ssh/ssh_host_ed25519_key.pub"
  )

  nix build \
    "${REPO_ROOT}#nixosConfigurations.${host}.config.system.build.diskoImagesScript" \
    --out-link "${build_dir}/result"

  (
    cd "${build_dir}"

    bash -x ./result \
      "${disko_args[@]}" \
      --build-memory 2048
  )

  local raw_image_path

  raw_image_path="$(
    find "${build_dir}" \
      -maxdepth 1 \
      -name "*.raw" \
      -print \
      -quit
  )"

  if [[ -z "${raw_image_path}" ]]; then
    echo
    echo "ERROR: No raw image found in:"
    echo "  ${build_dir}"
    return 1
  fi

  echo
  echo "Image build finished successfully:"
  echo "  ${raw_image_path}"
}

declare -A BUILD_PIDS

for host in "${HOSTS[@]}"; do
  build_dir="${SCRIPT_DIR}/build-${host}"
  mkdir -p "${build_dir}"

  echo "Building ${host}... Log: ${build_dir}/build.log"

  build_image "${host}" >"${build_dir}/build.log" 2>&1 &
  BUILD_PIDS["${host}"]=$!
done

BUILD_FAILED=0

for host in "${HOSTS[@]}"; do
  pid="${BUILD_PIDS[${host}]}"

  if wait "${pid}"; then
    echo
    echo "BUILD OK: ${host}"
  else
    echo "BUILD FAILED: ${host}"
    echo "  Log: ${SCRIPT_DIR}/build-${host}/build.log"
    BUILD_FAILED=1
  fi
done

if [[ "${BUILD_FAILED}" -ne 0 ]]; then
  echo
  echo " Image build failed!"
  echo " Existing VMs were NOT touched."
  exit 1
fi

echo
echo "========================================"
echo "Removing existing VM(s)"
echo "========================================"
echo

for host in "${HOSTS[@]}"; do
  echo
  echo "Processing existing VM: ${host}"

  if VBoxManage showvminfo "${host}" >/dev/null 2>&1; then
    echo "Stopping existing VM..."

    VBoxManage controlvm "${host}" poweroff 2>/dev/null || true

    sleep 2

    echo "Unregistering old VM..."

    VBoxManage unregistervm \
      "${host}" \
      --delete-all 2>/dev/null || true
  else
    echo "No registered VM found."
  fi

  VM_DIR="${HOME}/VirtualBox VMs/${host}"

  if [[ -d "${VM_DIR}" ]]; then
    echo "Removing stale VirtualBox VM directory:"
    echo "  ${VM_DIR}"

    rm -rf "${VM_DIR}"
  fi
done

for host in "${HOSTS[@]}"; do
  BUILD_DIR="${SCRIPT_DIR}/build-${host}"

  RAW_IMAGE_PATH="$(
    find "${BUILD_DIR}" \
      -maxdepth 1 \
      -name "*.raw" \
      -print \
      -quit
  )"

  if [[ -z "${RAW_IMAGE_PATH}" ]]; then
    echo "ERROR: No raw image found for ${host}:"
    echo "  ${BUILD_DIR}"
    exit 1
  fi

  VDI_OUTPUT="${BUILD_DIR}/vbox-${host}.vdi"

  echo
  echo "========================================"
  echo " Creating VM: ${host}"
  echo "========================================"

  rm -f "${VDI_OUTPUT}"

  echo "Converting RAW image to VDI..."

  VBoxManage convertfromraw \
    "${RAW_IMAGE_PATH}" \
    "${VDI_OUTPUT}" \
    --format VDI

  echo "Creating VirtualBox VM..."

  VBoxManage createvm \
    --name "${host}" \
    --ostype "Linux_64" \
    --register

  # BIOS is the default VirtualBox firmware.
  # Do not enable EFI.
  VBoxManage modifyvm "${host}" \
    --memory 6144 \
    --cpus 4

  VBoxManage storagectl "${host}" \
    --name "SATA Controller" \
    --add sata \
    --bootable on

  VBoxManage storageattach "${host}" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${VDI_OUTPUT}"

  # NIC1: normal LAN / Internet
  VBoxManage modifyvm "${host}" \
    --nic1 bridged \
    --bridgeadapter1 "${BRIDGE_INTERFACE}"

  # NIC2: host-only cluster network
  VBoxManage modifyvm "${host}" \
    --nic2 hostonly \
    --hostonlyadapter2 "vboxnet1"

  echo "VM created:"
  echo "  Name: ${host}"
  echo "  VDI:  ${VDI_OUTPUT}"
done

echo
echo "========================================"
echo " Starting VM(s)"
echo "========================================"
echo

for host in "${HOSTS[@]}"; do
  IP_ADDRESS="$(
    jq -r --arg host "${host}" \
      '.[$host].ipv4Address' \
      "${TARGETS_FILE}"
  )"

  echo "Starting ${host}..."

  VBoxManage startvm "${host}" --type headless

  echo "  Name: ${host}"
  echo "  IP:   ${IP_ADDRESS}"
done

echo
echo "========================================"
echo " VirtualBox deployment completed!"
echo "========================================"

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGETS_FILE="${SCRIPT_DIR}/.deploy-targets.json"
BRIDGE_SCRIPT="${SCRIPT_DIR}/bridge-interface.sh"
EXTRA_FILES_DIR="${SCRIPT_DIR}/extra-files"

# VirtualBox host-only cluster network
HOSTONLY_IP="192.168.63.1"
HOSTONLY_NETMASK="255.255.255.0"
HOSTONLY_INTERFACE=""

if command -v VBoxManage >/dev/null 2>&1; then
  VBOXMANAGE="VBoxManage"
elif [[ -x "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]]; then
  VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
else
  echo "ERROR: VBoxManage not found."
  echo "Expected Windows installation at:"
  echo "  C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe"
  exit 1
fi

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


# ============================================================
# VirtualBox host-only network
# ============================================================

ensure_hostonly_network() {
  echo
  echo "========================================"
  echo " Checking VirtualBox host-only network"
  echo "========================================"
  echo

  echo "Looking for host-only network:"
  echo "  IP:      ${HOSTONLY_IP}"
  echo "  Netmask: ${HOSTONLY_NETMASK}"

  # Look for an existing host-only interface with the desired IP.
  HOSTONLY_INTERFACE="$(
    $VBOXMANAGE list hostonlyifs |
      awk -v wanted_ip="${HOSTONLY_IP}" '
        /^Name:/ {
          name=$2
        }

        /^IPAddress:/ && $2 == wanted_ip {
          print name
          exit
        }
      '
  )"

  if [[ -n "${HOSTONLY_INTERFACE}" ]]; then
    echo "Host-only interface already exists:"
    echo "  ${HOSTONLY_INTERFACE}"

    return 0
  fi

  echo
  echo "No matching host-only interface found."
  echo "Creating one..."

  CREATE_OUTPUT="$($VBOXMANAGE hostonlyif create 2>&1)" || {
    echo "ERROR: Failed to create VirtualBox host-only interface."
    echo
    echo "${CREATE_OUTPUT}"
    exit 1
  }

  echo "${CREATE_OUTPUT}"

  # Find the newly created interface.
  # VirtualBox normally creates vboxnet0, vboxnet1, ...
  HOSTONLY_INTERFACE="$(
    $VBOXMANAGE list hostonlyifs |
      awk -v wanted_ip="${HOSTONLY_IP}" '
        /^Name:/ {
          name=$2
        }

        /^IPAddress:/ && $2 == wanted_ip {
          print name
          exit
        }
      '
  )"

  if [[ -z "${HOSTONLY_INTERFACE}" ]]; then
    echo
    echo "No interface with ${HOSTONLY_IP} exists yet."
    echo "Configuring the newest host-only interface..."

    HOSTONLY_INTERFACE="$(
      $VBOXMANAGE list hostonlyifs |
        awk '
          /^Name:/ {
            name=$2
          }

          /^IPAddress:/ {
            last=name
          }

          END {
            if (last != "") {
              print last
            }
          }
        '
    )"
  fi

  if [[ -z "${HOSTONLY_INTERFACE}" ]]; then
    echo
    echo "ERROR: Could not determine created host-only interface."
    exit 1
  fi

  echo
  echo "Configuring host-only interface:"
  echo "  ${HOSTONLY_INTERFACE}"

  $VBOXMANAGE hostonlyif ipconfig "${HOSTONLY_INTERFACE}" \
    --ip "${HOSTONLY_IP}" \
    --netmask "${HOSTONLY_NETMASK}"

  echo
  echo "Host-only network ready:"
  echo "  Interface: ${HOSTONLY_INTERFACE}"
  echo "  Network:   ${HOSTONLY_IP}/24"
}


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


# ============================================================
# Prepare host-only network before doing anything else
# ============================================================

ensure_hostonly_network


# ============================================================
# Build Disko images
# ============================================================

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
  echo "Image build failed!"
  echo "Existing VMs were NOT touched."
  exit 1
fi


# ============================================================
# Remove existing VMs
# ============================================================

echo
echo "========================================"
echo " Removing existing VM(s)"
echo "========================================"
echo

for host in "${HOSTS[@]}"; do
  echo
  echo "Processing existing VM: ${host}"

  if $VBOXMANAGE showvminfo "${host}" >/dev/null 2>&1; then
    echo "Stopping existing VM..."

    $VBOXMANAGE controlvm "${host}" poweroff 2>/dev/null || true

    sleep 2

    echo "Unregistering old VM..."

    $VBOXMANAGE unregistervm \
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


# ============================================================
# Create VMs
# ============================================================

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

  $VBOXMANAGE convertfromraw \
    "${RAW_IMAGE_PATH}" \
    "${VDI_OUTPUT}" \
    --format VDI

  echo "Creating VirtualBox VM..."

  $VBOXMANAGE createvm \
    --name "${host}" \
    --ostype "Linux_64" \
    --register

  # BIOS is the default VirtualBox firmware.
  # Do not enable EFI.
  $VBOXMANAGE modifyvm "${host}" \
    --memory 6144 \
    --cpus 4

  $VBOXMANAGE storagectl "${host}" \
    --name "SATA Controller" \
    --add sata \
    --bootable on

  $VBOXMANAGE storageattach "${host}" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${VDI_OUTPUT}"

  # NIC1: normal LAN / Internet
  $VBOXMANAGE modifyvm "${host}" \
    --nic1 bridged \
    --bridgeadapter1 "${BRIDGE_INTERFACE}"

  # NIC2: host-only cluster network
  $VBOXMANAGE modifyvm "${host}" \
    --nic2 hostonly \
    --hostonlyadapter2 "${HOSTONLY_INTERFACE}"

  echo
  echo "VM created:"
  echo "  Name:      ${host}"
  echo "  VDI:       ${VDI_OUTPUT}"
  echo "  NIC1:      bridged (${BRIDGE_INTERFACE})"
  echo "  NIC2:      host-only (${HOSTONLY_INTERFACE})"
done


# ============================================================
# Start VMs
# ============================================================

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

  $VBOXMANAGE startvm "${host}" --type headless

  echo "  Name: ${host}"
  echo "  IP:   ${IP_ADDRESS}"
done


echo
echo "========================================"
echo " VirtualBox deployment completed!"
echo "========================================"

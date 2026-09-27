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

# shellcheck source=vbox-lib.sh
source "${SCRIPT_DIR}/vbox-lib.sh"

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

vbox_require

# Path of the raw image in <build dir>, or failure if there is none.
find_raw_image() {
  local build_dir="$1"
  local path

  path="$(
    find "${build_dir}" \
      -maxdepth 1 \
      -name "*.raw" \
      -print \
      -quit
  )"

  if [[ -z "${path}" ]]; then
    echo "ERROR: No raw image found in:" >&2
    echo "  ${build_dir}" >&2
    return 1
  fi

  printf '%s\n' "${path}"
}

# VBOX_IMAGE_DIR empty means "next to the build", hence :- rather than the
# - used when picking the platform default.
vdi_path() {
  local host="$1"
  local build_dir="$2"

  printf '%s\n' "${VBOX_IMAGE_DIR:-${build_dir}}/vbox-${host}.vdi"
}

# Run <func> <host> for every host in the background, logging each to
# build-<host>/<log name>. Non-zero if any host failed.
run_for_each_host() {
  local label="$1"
  local func="$2"
  local log_name="$3"

  local -A pids=()
  local failed=0
  local host
  local log

  for host in "${HOSTS[@]}"; do
    log="${SCRIPT_DIR}/build-${host}/${log_name}"

    echo "${label} ${host}... Log: ${log}"

    { "${func}" "${host}" 2>&1 | timestamp_lines; } >"${log}" &
    pids["${host}"]=$!
  done

  for host in "${HOSTS[@]}"; do
    if wait "${pids[${host}]}"; then
      echo
      echo "${label} OK: ${host}"
    else
      echo "${label} FAILED: ${host}"
      echo "  Log: ${SCRIPT_DIR}/build-${host}/${log_name}"
      failed=1
    fi
  done

  return "${failed}"
}

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
  HOSTONLY_INTERFACE="$(vbox_if_name_by_ip hostonlyifs "${HOSTONLY_IP}")"

  if [[ -n "${HOSTONLY_INTERFACE}" ]]; then
    echo "Host-only interface already exists:"
    echo "  ${HOSTONLY_INTERFACE}"

    return 0
  fi

  echo
  echo "No matching host-only interface found."
  echo "Creating one..."

  CREATE_OUTPUT="$(vbox_out_merged hostonlyif create)" || {
    echo "ERROR: Failed to create VirtualBox host-only interface."
    echo
    echo "${CREATE_OUTPUT}"
    exit 1
  }

  echo "${CREATE_OUTPUT}"

  # Find the newly created interface.
  HOSTONLY_INTERFACE="$(vbox_if_name_by_ip hostonlyifs "${HOSTONLY_IP}")"

  if [[ -z "${HOSTONLY_INTERFACE}" ]]; then
    echo
    echo "No interface with ${HOSTONLY_IP} exists yet."
    echo "Configuring the newest host-only interface..."

    # Linux names these vboxnet0, vboxnet1, ...
    # Windows uses "VirtualBox Host-Only Ethernet Adapter [#N]".
    HOSTONLY_INTERFACE="$(vbox_last_if_name hostonlyifs)"
  fi

  if [[ -z "${HOSTONLY_INTERFACE}" ]]; then
    echo
    echo "ERROR: Could not determine created host-only interface."
    exit 1
  fi

  echo
  echo "Configuring host-only interface:"
  echo "  ${HOSTONLY_INTERFACE}"

  vbox hostonlyif ipconfig "${HOSTONLY_INTERFACE}" \
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
# Locate the VirtualBox machine folder
# ============================================================
#
# Under WSL this is on the Windows side, not under ${HOME}.

MACHINE_FOLDER="$(vbox_machine_folder)"

# Guards the rm -rf in the VM removal loop below: an empty value there would
# make "${MACHINE_FOLDER}/${host}" resolve to / on an empty host.
if [[ -z "${MACHINE_FOLDER}" || "${MACHINE_FOLDER}" == "/" ]]; then
  echo "ERROR: Implausible VirtualBox machine folder: '${MACHINE_FOLDER}'"
  exit 1
fi

echo
echo "VirtualBox machine folder: ${MACHINE_FOLDER}"

# VDIs live on a Windows drive: the WSL virtual disk never shrinks back below
# its high-water mark. VBOX_IMAGE_DIR="" keeps them in the build directory.

if ((VBOX_ON_WINDOWS)); then
  VBOX_IMAGE_DIR="${VBOX_IMAGE_DIR-/mnt/c/vbox-images}"
else
  VBOX_IMAGE_DIR="${VBOX_IMAGE_DIR-}"
fi

if [[ -n "${VBOX_IMAGE_DIR}" ]]; then
  mkdir -p "${VBOX_IMAGE_DIR}"

  echo "Disk image directory:      ${VBOX_IMAGE_DIR}"
else
  echo "Disk image directory:      per-host build directory"
fi

phase_mark setup


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

  # Without enableParallelBuilding the builder VM gets one vCPU, which
  # serialises disko's nix store copy. Split the host's cores across the
  # builds running concurrently.
  local build_cores=$(( $(nproc) / ${#HOSTS[@]} ))

  if (( build_cores < 1 )); then
    build_cores=1
  fi

  (
    cd "${build_dir}"

    enableParallelBuilding=1 \
    NIX_BUILD_CORES="${build_cores}" \
    bash -x ./result \
      "${disko_args[@]}" \
      --build-memory 2048
  )

  local raw_image_path

  raw_image_path="$(find_raw_image "${build_dir}")"

  echo
  echo "Image build finished successfully:"
  echo "  ${raw_image_path}"
}


for host in "${HOSTS[@]}"; do
  # A build that dies after partitioning leaves a multi-gigabyte image behind.
  rm -rf "${SCRIPT_DIR}/build-${host}"
  mkdir -p "${SCRIPT_DIR}/build-${host}"
done

if ! run_for_each_host BUILD build_image build.log; then
  echo
  echo "Image build failed!"
  echo "Existing VMs were NOT touched."
  exit 1
fi

phase_mark build


# ============================================================
# Remove existing VMs
# ============================================================

echo
echo "========================================"
echo " Removing existing VM(s)"
echo "========================================"
echo

REGISTERED=()

for host in "${HOSTS[@]}"; do
  echo
  echo "Processing existing VM: ${host}"

  if vbox showvminfo "${host}" >/dev/null 2>&1; then
    echo "Stopping existing VM..."

    vbox controlvm "${host}" poweroff 2>/dev/null || true

    REGISTERED+=("${host}")
  else
    echo "No registered VM found."
  fi
done

# One settle for every VM rather than one per VM.
if [[ "${#REGISTERED[@]}" -gt 0 ]]; then
  sleep 2

  for host in "${REGISTERED[@]}"; do
    echo "Unregistering old VM: ${host}"

    vbox unregistervm \
      "${host}" \
      --delete-all 2>/dev/null || true
  done
fi

for host in "${HOSTS[@]}"; do
  VM_DIR="${MACHINE_FOLDER}/${host}"

  # -n on host as well: MACHINE_FOLDER alone is not the intended target.
  if [[ -n "${host}" && -d "${VM_DIR}" ]]; then
    echo "Removing stale VirtualBox VM directory:"
    echo "  ${VM_DIR}"

    rm -rf "${VM_DIR}"
  fi
done

phase_mark remove


# ============================================================
# Convert images to VDI
# ============================================================
#
# After VM removal: unregistervm --delete-all deletes attached media, which
# would take a freshly converted VDI with it.

echo
echo "========================================"
echo " Converting image(s) to VDI"
echo "========================================"
echo

convert_image() {
  local host="$1"

  local build_dir="${SCRIPT_DIR}/build-${host}"
  local raw_image_path
  local vdi_output

  raw_image_path="$(find_raw_image "${build_dir}")"
  vdi_output="$(vdi_path "${host}" "${build_dir}")"

  rm -f "${vdi_output}"

  echo "Converting RAW image to VDI..."
  echo "  From: ${raw_image_path}"
  echo "  To:   ${vdi_output}"

  vbox convertfromraw \
    "$(vbox_path "${raw_image_path}")" \
    "$(vbox_path "${vdi_output}")" \
    --format VDI

  # Keeps the WSL disk's high-water mark down; the next deploy rebuilds it.
  # KEEP_RAW_IMAGE=1 to retain it for debugging.
  if [[ -z "${KEEP_RAW_IMAGE:-}" ]]; then
    echo "Removing raw image: ${raw_image_path}"

    rm -f "${raw_image_path}"
  fi
}


if ! run_for_each_host CONVERT convert_image convert.log; then
  echo
  echo "Image conversion failed!"
  exit 1
fi

phase_mark convert


# ============================================================
# Create VMs
# ============================================================

for host in "${HOSTS[@]}"; do
  VDI_OUTPUT="$(vdi_path "${host}" "${SCRIPT_DIR}/build-${host}")"

  echo
  echo "========================================"
  echo " Creating VM: ${host}"
  echo "========================================"

  vbox createvm \
    --name "${host}" \
    --ostype "Linux_64" \
    --register

  # BIOS is the default VirtualBox firmware.
  # Do not enable EFI.
  vbox modifyvm "${host}" \
    --memory 6144 \
    --cpus 4

  vbox storagectl "${host}" \
    --name "SATA Controller" \
    --add sata \
    --bootable on

  vbox storageattach "${host}" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$(vbox_path "${VDI_OUTPUT}")"

  # NIC1: normal LAN / Internet
  vbox modifyvm "${host}" \
    --nic1 bridged \
    --bridgeadapter1 "${BRIDGE_INTERFACE}"

  # NIC2: host-only cluster network
  vbox modifyvm "${host}" \
    --nic2 hostonly \
    --hostonlyadapter2 "${HOSTONLY_INTERFACE}"

  echo
  echo "VM created:"
  echo "  Name:      ${host}"
  echo "  VDI:       ${VDI_OUTPUT}"
  echo "  NIC1:      bridged (${BRIDGE_INTERFACE})"
  echo "  NIC2:      host-only (${HOSTONLY_INTERFACE})"
done

phase_mark create


# ============================================================
# Start VMs
# ============================================================

echo
echo "========================================"
echo " Starting VM(s)"
echo "========================================"
echo

# Starting several VMs at once starves them: VirtualBox logs multi-minute TM
# catch-up lags and the guests miss their device-enumeration timeouts, landing
# in the initrd emergency shell. VM_START_DELAY=0 disables the stagger.
VM_START_DELAY="${VM_START_DELAY-45}"

started=0

for host in "${HOSTS[@]}"; do
  if ((started > 0 && VM_START_DELAY > 0)); then
    echo
    echo "Waiting ${VM_START_DELAY}s before starting the next VM..."

    sleep "${VM_START_DELAY}"
  fi

  IP_ADDRESS="$(
    jq -r --arg host "${host}" \
      '.[$host].ipv4Address' \
      "${TARGETS_FILE}"
  )"

  echo "Starting ${host}..."

  vbox startvm "${host}" --type headless

  started=$((started + 1))

  echo "  Name: ${host}"
  echo "  IP:   ${IP_ADDRESS}"
done


phase_mark start

echo
echo "========================================"
echo " VirtualBox deployment completed in $(format_duration "${SECONDS}")"
echo "========================================"

phase_summary

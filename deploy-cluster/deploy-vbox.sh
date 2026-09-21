#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

BOOTSTRAP_KEY="$(pwd)/.bootstrap/bootstrap-key"
BOOTSTRAP_PUBLIC_KEY_FILE="$(pwd)/.bootstrap/bootstrap-key.pub"

BOX_NAME="nixos-vbox"
BOX_FILE="nixos-vbox.box"

BOOTSTRAP_DIR=".bootstrap"
KEY_FILE="${BOOTSTRAP_DIR}/bootstrap-key"
PUBLIC_KEY_FILE="${BOOTSTRAP_DIR}/bootstrap-key.pub"

WORKDIR=""

cleanup() {
  rm -rf "${WORKDIR:-}"
}

trap cleanup EXIT


echo
echo "========================================"
echo " 0. Create/reuse bootstrap SSH key"
echo "========================================"
echo

mkdir -p "${BOOTSTRAP_DIR}"

if [[ ! -f "${KEY_FILE}" || ! -f "${PUBLIC_KEY_FILE}" ]]; then

  echo "Creating bootstrap SSH key..."

  ssh-keygen \
    -q \
    -t ed25519 \
    -N "" \
    -f "${KEY_FILE}" \
    -C "nixos-vagrant-bootstrap"

  chmod 600 "${KEY_FILE}"
  chmod 644 "${PUBLIC_KEY_FILE}"

  echo "Created:"
  echo "  ${KEY_FILE}"
  echo "  ${PUBLIC_KEY_FILE}"

else

  echo "Reusing existing bootstrap SSH key:"
  echo "  ${KEY_FILE}"

fi


echo
echo "========================================"
echo " 1. Build VirtualBox image"
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
echo "OVA:"
echo "  ${OVA_PATH}"


echo
echo "========================================"
echo " 2. Create Vagrant box"
echo "========================================"
echo

WORKDIR="$(mktemp -d)"

echo "Extracting OVA..."

tar \
  -xf "${OVA_PATH}" \
  -C "${WORKDIR}"

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
echo " 3. Update Vagrant box"
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
echo " 4. Start Vagrant cluster"
echo "========================================"
echo

vagrant destroy -f || true

echo "Starting n1-vm..."

vagrant up n1-vm &
PID_N1=$!

vagrant up n2-vm &
PID_N2=$!

vagrant up n3-vm &
PID_N3=$!

wait "${PID_N1}"
wait "${PID_N2}"
wait "${PID_N3}"


echo
echo "========================================"
echo " Vagrant cluster is running"
echo "========================================"
echo
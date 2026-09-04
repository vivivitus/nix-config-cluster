#!/usr/bin/env bash
set -euo pipefail

NETWORK="192.168.56.0/24"
HOST_IP="192.168.56.1"
HOST_IPV6="fd42:42:42::1"
NETMASK="255.255.255.0"

DISK_SIZE_MB=32768
MEMORY_MB=4096
CPUS=4

VMS=(
  "n1-vm"
  "n2-vm"
  "n3-vm"
)

echo "==> Creating VirtualBox host-only network"

if ! VBoxManage list hostonlyifs | grep -q '^Name:'; then
  VBoxManage hostonlyif create
fi

HOSTONLY_IF="$(
  VBoxManage list hostonlyifs |
    awk '/^Name:/ {print $2; exit}'
)"

echo "    Interface: ${HOSTONLY_IF}"

VBoxManage hostonlyif ipconfig "$HOSTONLY_IF" \
  --ip "$HOST_IP" \
  --netmask "$NETMASK"

echo "==> Creating VMs"

for VM in "${VMS[@]}"; do
  echo "    -> $VM"

  if VBoxManage list vms | grep -q "\"${VM}\""; then
    echo "       already exists, skipping"
    continue
  fi

  VBoxManage createvm \
    --name "$VM" \
    --ostype "Linux_64" \
    --register

  VBoxManage modifyvm "$VM" \
    --memory "$MEMORY_MB" \
    --cpus "$CPUS" \
    --firmware efi \
    --audio-enabled off \
    --usb-ohci off \
    --nic1 hostonly \
    --hostonlyadapter1 "$HOSTONLY_IF"

  DISK="${PWD}/${VM}.vdi"

  VBoxManage createmedium disk \
    --filename "$DISK" \
    --size "$DISK_SIZE_MB" \
    --format VDI

  VBoxManage storagectl "$VM" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci

  VBoxManage storageattach "$VM" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$DISK"

done

echo
echo "==> Cluster created"
echo
VBoxManage list vms
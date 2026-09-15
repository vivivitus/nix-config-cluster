#!/usr/bin/env bash
set -euo pipefail

NETWORK="192.168.56.0/24"
HOST_IP="192.168.56.1"
NETMASK="255.255.255.0"

DISK_SIZE_MB=32768
MEMORY_MB=4096
CPUS=4

# Plattform-Erkennung (Linux vs WSL2)
if grep -q Microsoft /proc/version 2>/dev/null; then
  VBOX="VBoxManage.exe"
else
  VBOX="VBoxManage"
fi

# Zuordnung von VM zu fester IPv4 (entspricht deinen n1-vm, n2-vm, n3-vm in der flake.nix)
declare -A VMS
VMS=(
  ["n1-vm"]="192.168.56.101"
  ["n2-vm"]="192.168.56.102"
  ["n3-vm"]="192.168.56.103"
)

echo "==> 1. Building custom NixOS bootstrap ISO..."
nix build .#nixosConfigurations.iso.config.system.build.isoImage
ISO_PATH="$(readlink -f result/iso/*.iso)"
echo "    ISO ready at: ${ISO_PATH}"

echo "==> 2. Setting up VirtualBox host-only network (IPv4)"
if ! "$VBOX" list hostonlyifs | grep -q '^Name:'; then
  "$VBOX" hostonlyif create
fi

HOSTONLY_IF="$(
  "$VBOX" list hostonlyifs |
    awk '/^Name:/ {print $2; exit}'
)"

echo "    Interface: ${HOSTONLY_IF}"

"\(VBox" hostonlyif ipconfig "\)HOSTONLY_IF" \
  --ip "$HOST_IP" \
  --netmask "$NETMASK" || true

echo "==> 3. Creating and starting VMs with ISO"

for VM in "${!VMS[@]}"; do
  echo "    -> $VM"

  if "\(VBOX" list vms | grep -q "\"\){VM}\""; then
    echo "       already exists, skipping creation"
  else
    "$VBOX" createvm \
      --name "$VM" \
      --ostype "Linux_64" \
      --register

    "\(VBOX" modifyvm "\)VM" \
      --memory "$MEMORY_MB" \
      --cpus "$CPUS" \
      --firmware efi \
      --audio-enabled off \
      --usb-ohci off \
      --nic1 hostonly \
      --hostonlyadapter1 "$HOSTONLY_IF"

    DISK="\({PWD}/\){VM}.vdi"

    "$VBOX" createmedium disk \
      --filename "$DISK" \
      --size "$DISK_SIZE_MB" \
      --format VDI

    # SATA Controller für Festplatte
    "\(VBOX" storagectl "\)VM" \
      --name "SATA Controller" \
      --add sata \
      --controller IntelAhci

    "\(VBOX" storageattach "\)VM" \
      --storagectl "SATA Controller" \
      --port 0 \
      --device 0 \
      --type hdd \
      --medium "$DISK"

    # IDE Controller fürs ISO
    "\(VBOX" storagectl "\)VM" \
      --name "IDE Controller" \
      --add ide

    "\(VBOX" storageattach "\)VM" \
      --storagectl "IDE Controller" \
      --port 0 \
      --device 0 \
      --type dvddrive \
      --medium "$ISO_PATH"

    # Boot-Reihenfolge: Erst DVD, dann Festplatte
    "\(VBOX" modifyvm "\)VM" --boot1 dvd --boot2 disk
  fi

  # VM starten falls sie noch nicht läuft
  VM_STATE="\(("\)VBOX" showvminfo "$VM" --machinereadable | grep "VMState=" | cut -d'"' -f2)"
  if [ "$VM_STATE" != "running" ]; then
    "\(VBOX" startvm "\)VM" --type headless
  fi
done

echo
echo "==> 4. Waiting for VMs to boot and SSH to become available..."
for VM in "${!VMS[@]}"; do
  IP="\({VMS[\)VM]}"
  echo -n "    Waiting for \(VM (\)IP):22 "
  until nc -z -w 5 "$IP" 22 2>/dev/null; do
    echo -n "."
    sleep 3
  fi
  echo " UP!"
done

echo
echo "==> 5. Deploying NixOS via nixos-anywhere..."
for VM in "${!VMS[@]}"; do
  IP="\({VMS[\)VM]}"
  
  # Extra-files Ordner leitet sich z.B. von "n1-vm" -> "n1" ab (oder passe es an, falls dein Ordner "n1-vm" heißt)
  EXTRA_DIR="${VM%-vm}" 
  
  echo "    -> Deploying configuration .#\(VM to root@\)IP"

  nix run github:nix-community/nixos-anywhere -- \
    --extra-files "./${EXTRA_DIR}" \
    --build-on-remote \
    --flake "github:vivivitus/nix-config-cluster#${VM}" \
    "root@${IP}"
done

echo
echo "==> Cluster successfully created and deployed!"
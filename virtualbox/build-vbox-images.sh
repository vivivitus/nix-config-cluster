#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/result-vbox"

VMS=(
  "n1-vm"
  "n2-vm"
  "n3-vm"
)

mkdir -p "$OUT"

echo "========================================"
echo " Building VirtualBox images"
echo "========================================"
echo "Root: $ROOT"
echo "Output: $OUT"
echo

for VM in "${VMS[@]}"; do
  echo
  echo "========================================"
  echo " Building: $VM"
  echo "========================================"
  echo

  nix build \
    "$ROOT#nixosConfigurations.${VM}.config.system.build.virtualBoxOVA" \
    --out-link "$OUT/${VM}" \
    --print-build-logs

  echo
  echo "==> $VM finished"
done

echo
echo "========================================"
echo " All VirtualBox images built"
echo "========================================"
echo

for VM in "${VMS[@]}"; do
  echo "${VM}:"

  if [ -e "$OUT/${VM}" ]; then
    find "$OUT/${VM}" -maxdepth 2 -type f \
      \( -name '*.ova' -o -name '*.ovf' \) \
      -print
  else
    echo "  ERROR: output not found"
  fi
done
#!/usr/bin/env bash

set -euo pipefail

if grep -qi microsoft /proc/version 2>/dev/null; then

  VBOXMANAGE="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"

  interface_ip="$(
  route.exe print 0.0.0.0 |
  tr -d '\r' |
  awk '
  /^ *0\.0\.0\.0 +0\.0\.0\.0/ {
    print $4
    exit
  }
  '
  )"

  [ -n "$interface_ip" ] ||
  abort "Could not determine Windows default-route interface IP"

  bridge_interface="$(
  "$VBOXMANAGE" list bridgedifs |
  tr -d '\r' |
  awk -v ip="$interface_ip" '
  /^Name:/ {
    name = $0
    sub(/^[^:]*:[[:space:]]*/, "", name)
  }

  /^IPAddress:/ {
    address = $0
    sub(/^[^:]*:[[:space:]]*/, "", address)

    if (address == ip) {
      print name
      exit
    }
  }
  '
  )"

  [ -n "$bridge_interface" ] ||
  {
    echo "Could not find VirtualBox bridged interface for IP $interface_ip" >&2
    exit 1
  }

  printf '%s\n' "$bridge_interface"

else

  ip -4 route show default |
  awk '
  /default/ {
    for (i = 1; i <= NF; i++)
    if ($i == "dev") {
      print $(i+1)
      exit
    }
  }
  '

fi

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=vbox-lib.sh
source "${SCRIPT_DIR}/vbox-lib.sh"

if ((VBOX_ON_WINDOWS)); then

  vbox_require

  interface_ip="$(
    route.exe print 0.0.0.0 |
      tr -d '\r' |
      awk '
        /^ *0\.0\.0\.0 +0\.0\.0\.0/ {
          if (ip == "") {
            ip = $4
          }
        }

        END {
          if (ip != "") {
            print ip
          }
        }
      '
  )"

  if [[ -z "${interface_ip}" ]]; then
    echo "ERROR: Could not determine the Windows default-route interface IP." >&2
    exit 1
  fi

  bridge_interface="$(vbox_if_name_by_ip bridgedifs "${interface_ip}")"
  error="No VirtualBox bridged interface for IP ${interface_ip}."

else

  bridge_interface="$(
    ip -4 route show default |
      awk '
        /default/ {
          for (i = 1; i <= NF; i++) {
            if ($i == "dev" && dev == "") {
              dev = $(i + 1)
            }
          }
        }

        END {
          if (dev != "") {
            print dev
          }
        }
      '
  )"
  error="Could not determine the default-route interface."

fi

if [[ -z "${bridge_interface}" ]]; then
  echo "ERROR: ${error}" >&2
  exit 1
fi

printf '%s\n' "${bridge_interface}"

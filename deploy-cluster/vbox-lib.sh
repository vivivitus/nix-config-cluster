#!/usr/bin/env bash
#
# Shared VBoxManage helpers for the native Linux binary or the Windows one
# under WSL. Source this file; vbox_out() needs the caller's pipefail.

if [[ -n "${VBOX_LIB_SOURCED:-}" ]]; then
  return 0
fi

VBOX_LIB_SOURCED=1

VBOXMANAGE_WINDOWS_PATH="${VBOXMANAGE_WINDOWS_PATH:-/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe}"

# An array, not a string: the Windows path contains a space.
if command -v VBoxManage >/dev/null 2>&1; then
  VBOXMANAGE=(VBoxManage)
  VBOX_ON_WINDOWS=0
elif [[ -x "${VBOXMANAGE_WINDOWS_PATH}" ]]; then
  VBOXMANAGE=("${VBOXMANAGE_WINDOWS_PATH}")
  VBOX_ON_WINDOWS=1
else
  VBOXMANAGE=()
  VBOX_ON_WINDOWS=0
fi

# awk helper shared by the list parsers below: turns "Key:   value  " into
# "value". A string so each program can prepend it.
VBOX_AWK_VALUE='
  function value(line) {
    sub(/^[^:]*:[[:space:]]*/, "", line)
    sub(/[[:space:]]+$/, "", line)

    return line
  }
'


# Abort unless VBoxManage is usable. Call before the first vbox* invocation;
# sourcing alone stays cheap so callers that only need VBOX_ON_WINDOWS work
# without VirtualBox installed.
vbox_require() {
  if [[ "${#VBOXMANAGE[@]}" -eq 0 ]]; then
    echo "ERROR: VBoxManage not found." >&2
    echo "Looked for a native VBoxManage on PATH, and for:" >&2
    echo "  ${VBOXMANAGE_WINDOWS_PATH}" >&2
    exit 1
  fi

  if ((VBOX_ON_WINDOWS)) && ! command -v wslpath >/dev/null 2>&1; then
    echo "ERROR: Using the Windows VBoxManage but wslpath is unavailable." >&2
    echo "Paths cannot be translated for it." >&2
    exit 1
  fi
}

vbox() {
  "${VBOXMANAGE[@]}" "$@"
}

# For parsing: the Windows binary emits CRLF, and a trailing \r breaks every
# comparison and every name handed back to VirtualBox.
vbox_out() {
  "${VBOXMANAGE[@]}" "$@" | tr -d '\r'
}

# As vbox_out, with stderr folded in.
vbox_out_merged() {
  "${VBOXMANAGE[@]}" "$@" 2>&1 | tr -d '\r'
}

# WSL path -> whatever the VBoxManage in use can resolve.
vbox_path() {
  local path="$1"

  if ((VBOX_ON_WINDOWS)); then
    wslpath -w -a "${path}"
  else
    printf '%s\n' "${path}"
  fi
}

# VBoxManage-reported path -> one this shell can use.
host_path() {
  local path="$1"

  if ((VBOX_ON_WINDOWS)); then
    wslpath -u "${path}"
  else
    printf '%s\n' "${path}"
  fi
}

# Name of the interface in `list <listing>` whose IPAddress equals <ip>.
#
# The name is everything after the first colon, not $2: Windows adapters look
# like "VirtualBox Host-Only Ethernet Adapter #2". Do not exit awk early --
# SIGPIPE on VBoxManage would surface as a pipefail failure.
vbox_if_name_by_ip() {
  local listing="$1"
  local wanted_ip="$2"

  vbox_out list "${listing}" |
    awk -v wanted_ip="${wanted_ip}" "${VBOX_AWK_VALUE}"'
      /^Name:/ {
        name = value($0)
      }

      /^IPAddress:/ {
        if (match_name == "" && value($0) == wanted_ip) {
          match_name = name
        }
      }

      END {
        if (match_name != "") {
          print match_name
        }
      }
    '
}

# Fallback for a freshly created interface with no address yet.
vbox_last_if_name() {
  local listing="$1"

  vbox_out list "${listing}" |
    awk "${VBOX_AWK_VALUE}"'
      /^Name:/ {
        name = value($0)
      }

      /^IPAddress:/ {
        last = name
      }

      END {
        if (last != "") {
          print last
        }
      }
    '
}

# VirtualBox's default machine folder, in this shell's path namespace.
vbox_machine_folder() {
  local folder

  folder="$(
    vbox_out list systemproperties |
      awk "${VBOX_AWK_VALUE}"'
        /^Default machine folder:/ {
          if (folder == "") {
            folder = value($0)
          }
        }

        END {
          if (folder != "") {
            print folder
          }
        }
      '
  )"

  if [[ -z "${folder}" ]]; then
    echo "ERROR: Could not determine the VirtualBox default machine folder." >&2
    return 1
  fi

  host_path "${folder}"
}

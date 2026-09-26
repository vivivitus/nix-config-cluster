#!/usr/bin/env bash
#
# Generic shell helpers, nothing VirtualBox-specific. Source this file.

if [[ -n "${COMMON_LIB_SOURCED:-}" ]]; then
  return 0
fi

COMMON_LIB_SOURCED=1

PHASE_NAMES=()
PHASE_SECONDS=()
PHASE_MARK=0


# Seconds as "6m 59s".
format_duration() {
  local total="$1"

  if ((total >= 60)); then
    printf '%dm %02ds\n' $((total / 60)) $((total % 60))
  else
    printf '%ds\n' "${total}"
  fi
}

# Prefix each line with an ISO 8601 timestamp.
timestamp_lines() {
  local line

  while IFS= read -r line || [[ -n "${line}" ]]; do
    printf '%(%Y-%m-%dT%H:%M:%S%z)T %s\n' -1 "${line}"
  done
}

# Record the time since the previous mark under <name>. Relies on SECONDS, so
# the durations are measured from the start of the calling script.
phase_mark() {
  PHASE_NAMES+=("$1")
  PHASE_SECONDS+=("$((SECONDS - PHASE_MARK))")
  PHASE_MARK="${SECONDS}"
}

phase_summary() {
  local i

  for i in "${!PHASE_NAMES[@]}"; do
    printf '  %-10s %s\n' "${PHASE_NAMES[i]}" "$(format_duration "${PHASE_SECONDS[i]}")"
  done
}

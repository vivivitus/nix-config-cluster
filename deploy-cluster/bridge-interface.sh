#!/usr/bin/env bash
set -euo pipefail

if grep -qi microsoft /proc/version 2>/dev/null; then
    powershell.exe -NoProfile -Command \
        "(Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
          Sort-Object RouteMetric |
          Select-Object -First 1).InterfaceAlias" |
        tr -d '\r'
else
    ip -4 route show default |
        awk '/default/ {
            for (i = 1; i <= NF; i++)
                if ($i == "dev") {
                    print $(i+1)
                    exit
                }
        }'
fi
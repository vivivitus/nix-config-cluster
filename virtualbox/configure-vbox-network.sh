```bash
#!/usr/bin/env bash
set -euo pipefail

HOSTONLY_IF="vboxnet0"

IPV4_NETWORK="192.168.56.0/24"
IPV4_HOST="192.168.56.1"
IPV4_NETMASK="255.255.255.0"

IPV6_NETWORK="fd42:42:42::/64"
IPV6_HOST="fd42:42:42::1/64"

echo "==> Detecting Internet interface"

INTERNET_IF="$(
  ip route get 8.8.8.8 |
    awk '
      {
        for (i = 1; i <= NF; i++) {
          if ($i == "dev") {
            print $(i + 1)
            exit
          }
        }
      }
    '
)"

if [[ -z "$INTERNET_IF" ]]; then
  echo "ERROR: Could not determine Internet interface"
  exit 1
fi

echo "    Internet interface: ${INTERNET_IF}"

echo "==> Checking VirtualBox host-only interface"

if ! VBoxManage list hostonlyifs | grep -q "^Name:[[:space:]]*${HOSTONLY_IF}$"; then
  echo "ERROR: ${HOSTONLY_IF} does not exist"
  echo "       Run create-vbox-cluster.sh first."
  exit 1
fi

echo "==> Configuring IPv4"

sudo VBoxManage hostonlyif ipconfig "$HOSTONLY_IF" \
  --ip "$IPV4_HOST" \
  --netmask "$IPV4_NETMASK"

echo "==> Configuring IPv6"

if ! ip -6 addr show dev "$HOSTONLY_IF" | grep -q "fd42:42:42::1/64"; then
  sudo ip -6 addr add "$IPV6_HOST" dev "$HOSTONLY_IF"
fi

echo "==> Enabling IPv4 forwarding"

sudo sysctl -w net.ipv4.ip_forward=1

echo "==> Enabling IPv6 forwarding"

sudo sysctl -w net.ipv6.conf.all.forwarding=1

echo "==> Configuring IPv4 NAT"

if ! sudo iptables -t nat -C POSTROUTING \
    -s "$IPV4_NETWORK" \
    -o "$INTERNET_IF" \
    -j MASQUERADE 2>/dev/null; then

  sudo iptables -t nat -A POSTROUTING \
    -s "$IPV4_NETWORK" \
    -o "$INTERNET_IF" \
    -j MASQUERADE
fi

echo "==> Configuring forwarding rules"

if ! sudo iptables -C FORWARD \
    -i "$HOSTONLY_IF" \
    -o "$INTERNET_IF" \
    -s "$IPV4_NETWORK" \
    -j ACCEPT 2>/dev/null; then

  sudo iptables -A FORWARD \
    -i "$HOSTONLY_IF" \
    -o "$INTERNET_IF" \
    -s "$IPV4_NETWORK" \
    -j ACCEPT
fi

if ! sudo iptables -C FORWARD \
    -i "$INTERNET_IF" \
    -o "$HOSTONLY_IF" \
    -d "$IPV4_NETWORK" \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT 2>/dev/null; then

  sudo iptables -A FORWARD \
    -i "$INTERNET_IF" \
    -o "$HOSTONLY_IF" \
    -d "$IPV4_NETWORK" \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT
fi

echo
echo "==> VirtualBox network configured"
echo
echo "    Interface: ${HOSTONLY_IF}"
echo "    IPv4:     ${IPV4_HOST}/24"
echo "    IPv6:     ${IPV6_HOST}"
echo "    Internet: ${INTERNET_IF}"
echo
echo "    VM network:"
echo "      n1-vm  192.168.56.101  fd42:42:42::101"
echo "      n2-vm  192.168.56.102  fd42:42:42::102"
echo "      n3-vm  192.168.56.103  fd42:42:42::103"
```

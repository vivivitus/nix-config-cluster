#!/usr/bin/env bash
# providers/vbox.sh

set -euo pipefail

: "${HOST_IP:?HOST_IP is required}"
: "${NETMASK:?NETMASK is required}"
: "${MEMORY_MB:?MEMORY_MB is required}"
: "${CPUS:?CPUS is required}"
: "${DISK_SIZE_MB:?DISK_SIZE_MB is required}"
: "${VMS_NAME:?VMS_NAME is required}"
: "${VMS_IP:?VMS_IP is required}"
: "${VMS_MAC:?VMS_MAC is required}"
: "${DHCP_LOWER_IP:?DHCP_LOWER_IP is required}"
: "${DHCP_UPPER_IP:?DHCP_UPPER_IP is required}"

vbox_init() {
    HOST_PHYSICAL_IFACE="${HOST_PHYSICAL_IFACE:-$(ip route show default | awk '{print $5; exit}')}"
    if [[ -z "$HOST_PHYSICAL_IFACE" ]]; then
        echo "ERROR: Could not determine default physical network interface." >&2
        return 1
    fi

    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        VBOX="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
    else
        VBOX="VBoxManage"
    fi

    VBOX_DEFAULT_MACHINE_FOLDER="$("$VBOX" list systemproperties | grep '^Default machine folder:' | cut -d':' -f2- | xargs)"
    if [[ -z "$VBOX_DEFAULT_MACHINE_FOLDER" ]]; then
        echo "ERROR: Could not determine VirtualBox default machine folder."
        return 1
    fi
}

vbox_vm_is_running() {
    local vm="$1"
    local state
    state="$("$VBOX" showvminfo "$vm" --machinereadable 2>/dev/null | grep '^VMState=' | cut -d'"' -f2)" || state="unknown"
    [[ "$state" = "running" ]]
}

setup_network() {
    vbox_init
    echo "Configuring VirtualBox network..."

    HOSTONLY_IF=""
    IFACE_INFO="$("$VBOX" list hostonlyifs)"

    while IFS= read -r line; do
        if [[ "$line" =~ ^Name:[[:space:]]*(.*)$ ]]; then
            current_if="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^IPAddress:[[:space:]]*(.*)$ ]]; then
            local ip="${BASH_REMATCH[1]}"
            if [[ "$ip" = "$HOST_IP" ]]; then
                HOSTONLY_IF="$current_if"
                break
            fi
        fi
    done < <("$VBOX" list hostonlyifs | tr -d '\r')

    if [[ -z "$HOSTONLY_IF" ]]; then
        CREATE_OUTPUT="$("$VBOX" hostonlyif create | tr -d '\r')"
        HOSTONLY_IF="${CREATE_OUTPUT#Interface \'}"
        HOSTONLY_IF="${HOSTONLY_IF%%\'*}"
    fi

    "$VBOX" hostonlyif ipconfig "$HOSTONLY_IF" --ip "$HOST_IP" --netmask "$NETMASK"

    # DHCP Setup
    "$VBOX" dhcpserver remove --interface "$HOSTONLY_IF" 2>/dev/null || true
    "$VBOX" dhcpserver add --interface "$HOSTONLY_IF" --ip "$HOST_IP" --netmask "$NETMASK" --lower-ip "$DHCP_LOWER_IP" --upper-ip "$DHCP_UPPER_IP"
    "$VBOX" dhcpserver modify --interface "$HOSTONLY_IF" --enable

    for i in "${!VMS_NAME[@]}"; do
        "$VBOX" dhcpserver modify --interface "$HOSTONLY_IF" --mac-address "${VMS_MAC[$i]}" --fixed-address "${VMS_IP[$i]}"
    done
    "$VBOX" dhcpserver start --interface "$HOSTONLY_IF" 2>/dev/null || true
}

create_vms() {
    local iso_path="$1"
    vbox_init
    echo "Configuring VirtualBox VMs..."

    for i in "${!VMS_NAME[@]}"; do
        local VM="${VMS_NAME[$i]}"
        local IP="${VMS_IP[$i]}"
        local MAC="${VMS_MAC[$i]}"
        local VM_DIR="${VBOX_DEFAULT_MACHINE_FOLDER}/${VM}"
        local DISK="${VM_DIR}/${VM}.vdi"

        if ! "$VBOX" showvminfo "$VM" >/dev/null 2>&1; then
            "$VBOX" createvm --name "$VM" --register
        else
            if vbox_vm_is_running "$VM"; then
                "$VBOX" controlvm "$VM" poweroff
                timeout=30
                while vbox_vm_is_running "$VM"; do
                    sleep 1
                    timeout=$((timeout-1))
                    if [[ $timeout -le 0 ]]; then
                        echo "ERROR: VM '$VM' failed to stop within 30 seconds" >&2
                        exit 1
                    fi
                done
            fi
        fi

        "$VBOX" modifyvm "$VM" --memory "$MEMORY_MB" --cpus "$CPUS" --ostype "Linux_64" --firmware efi
        "$VBOX" modifyvm "$VM" --nic1 bridged --bridgeadapter1 "$HOST_PHYSICAL_IFACE" --nic2 hostonly --hostonlyadapter2 "$HOSTONLY_IF" --macaddress2 "$MAC"

        if [[ ! -f "$DISK" ]]; then
            "$VBOX" createmedium disk --filename "$DISK" --size "$DISK_SIZE_MB" --format VDI
        fi

        if ! "$VBOX" showvminfo "$VM" --machinereadable | grep -q 'storagecontrollername.*="SATA"'; then
            "$VBOX" storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
        fi
        if ! "$VBOX" showvminfo "$VM" --machinereadable | grep -q 'SATA-0-0='; then
            "$VBOX" storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISK"
        fi
        if ! "$VBOX" showvminfo "$VM" --machinereadable | grep -q 'storagecontrollername.*="IDE Controller"'; then
            "$VBOX" storagectl "$VM" --name "IDE Controller" --add ide
        fi

        # ISO und Boot-Reihenfolge erzwingen
        "$VBOX" storageattach "$VM" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$iso_path"
        "$VBOX" modifyvm "$VM" --boot1 dvd --boot2 disk

        # NVRAM löschen, falls vorhanden (mit || true abgesichert gegen set -e)
        rm -f "${VM_DIR:?VM_DIR is unset}/${VM}.nvram" 2>/dev/null || true
    done
}

start_vms() {
    vbox_init
    for VM in "${VMS_NAME[@]}"; do
        if vbox_vm_is_running "$VM"; then
            echo "${VM} is already running."
        else
            echo "Starting ${VM}..."
            "$VBOX" startvm "$VM" --type headless
        fi
    done
}

finalize_vms() {
    vbox_init
    for VM in "${VMS_NAME[@]}"; do
        echo "Finalizing ${VM}..."
        "$VBOX" controlvm "$VM" acpipowerbutton
        
        while vbox_vm_is_running "$VM"; do
            sleep 2
        done

        "$VBOX" storageattach "$VM" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium none
        "$VBOX" modifyvm "$VM" --boot1 disk --boot2 none
        "$VBOX" startvm "$VM" --type headless
    done
}
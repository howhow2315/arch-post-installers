#!/bin/bash
[[ ! $COMMON_INITIALIZED ]] && source ./common.sh

#### ZRAM ####
_silently pacman -Qi zram-generator || _run_as_root pacman -S --noconfirm zram-generator

_notif "Writing /etc/systemd/zram-generator.conf..." o
_run_as_root tee /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = max(ram / 2, 8192)
compression-algorithm = lz4
swap-priority = 100
EOF

_notif "Writing /etc/sysctl.d/99-vm-zram-parameters.conf..." o
_run_as_root tee /etc/sysctl.d/99-vm-zram-parameters.conf <<'EOF'
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

_notif "Restarting ZRAM service..." o
_run_as_root systemctl restart systemd-zram-setup@zram0.service

#### SWAP ####
if [[ $(_get_rotational_flag "/") -eq 0 ]]; then
    DISK_MB=$(df --output=size / | tail -1) # Total root disk size in KB
    DISK_MB=$(( DISK_MB / 1024 )) # convert from KB -> MB
    MAX_DISK_PERCENT_MB=$(( DISK_MB * 4 / 100 ))
    RAM_MB=$(awk '/MemTotal/ {printf "%.0f\n",$2/1024}' /proc/meminfo) # Total RAM in MB

    # Convert constants to MB
    MIN_GB_MB=$((4 * 1024)) # We want atleast 4GB of swap
    MAX_GB_MB=$((24 * 1024)) # We dont need more than 24GB of swap

    SWAP_MB=$(( RAM_MB * 75 / 100 )) # swap_size = clamp(RAM * 0.75, 8GB, 16GB)
    (( SWAP_MB < MIN_GB_MB )) && SWAP_MB=$MIN_GB_MB # Clamp to min of 4GB
    (( SWAP_MB > MAX_GB_MB )) && SWAP_MB=$MAX_GB_MB # Clamp to max of 24GB
    (( SWAP_MB > MAX_DISK_PERCENT_MB )) && SWAP_MB=$MAX_DISK_PERCENT_MB # Clamp to max of 4% of / disk size

    SWAPFILE="/swapfile"

    # If swap is active, turn it off
    if _run_as_root swapon --show=NAME | grep -q "^$SWAPFILE$"; then
        _notif "Swap file $SWAPFILE is active. Turning off..."
        _run_as_root swapoff "$SWAPFILE"
    fi

    # Remove existing swap file if it exists
    if [ -f "$SWAPFILE" ]; then
        _notif "Removing existing swap file..."
        _run_as_root rm -f "$SWAPFILE"
    fi

    # Create new swap file
    _notif "Creating swap file of ${SWAP_MB} MB..."
    _run_as_root fallocate -l "${SWAP_MB}M" "$SWAPFILE"
    _run_as_root chmod 600 "$SWAPFILE"
    _run_as_root mkswap "$SWAPFILE"
    _run_as_root swapon "$SWAPFILE"

    # Make permanent in fstab
    grep -q "^$SWAPFILE" /etc/fstab || echo "$SWAPFILE none swap defaults 0 0" | _run_as_root tee -a /etc/fstab

    # Set swappiness
    echo "vm.swappiness=20" | _run_as_root tee /etc/sysctl.d/99-swappiness.conf

    _notif "Swap file recreated and enabled." o
else
    _notif "Root device is not an SSD, not creating swap" !
fi

_notif "Applying sysctl parameters..." o
_run_as_root sysctl --system
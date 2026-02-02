#!/bin/sh
# Custom preinit for Atomic Green - Immutable root with overlay persistence

echo "Atomic Green Immutable System"
echo "Starting custom boot sequence...\n"
sleep 3

echo "[1/5] Detecting persistence partition..."
# Prioritize UUID from cmdline (explicit and recommended)
DATA_DEVICE=""
if grep -q "immutable.data_uuid=" /proc/cmdline; then
    UUID=$(grep -o 'immutable.data_uuid=[^ ]*' /proc/cmdline | cut -d= -f2)
    echo "UUID provided via cmdline: $UUID"
    DATA_DEVICE="/dev/disk/by-uuid/$UUID"
else
    echo "No UUID provided via cmdline. Falling back to LABEL=DATA..."
    DATA_DEVICE="LABEL=DATA"
fi
sleep 3

echo "[2/5] Mounting persistence partition..."
mkdir -p /mnt/data
mount $DATA_DEVICE /mnt/data || {
    echo "ERROR: Failed to mount persistence partition."
    echo "Check:"
    echo "  - If UUID is correct in GRUB parameter immutable.data_uuid="
    echo "  - Or if partition has LABEL=DATA"
    echo "  - Command attempted: mount $DATA_DEVICE /mnt/data"
    exec /bin/sh
}
echo "Persistence partition mounted successfully."
sleep 3

echo "[3/5] Preparing overlay layers..."
mkdir -p /mnt/data/upper /mnt/data/work
echo "Upper and work directories ready."
sleep 3

echo "[4/5] Mounting overlayfs (immutable root + persistence)..."
mkdir -p /mnt/newroot
mount -t overlay overlay \
    -o lowerdir=/,upperdir=/mnt/data/upper,workdir=/mnt/data/work \
    /mnt/newroot || {
    echo "ERROR: Failed to mount overlay"
    exec /bin/sh
}
echo "Overlay mounted. Changes will be persisted on DATA partition."
sleep 3

echo "[5/5] Preparing environment and handing over control..."
mkdir -p /mnt/newroot/{proc,sys,dev,run,dev/pts,var/tmp}

mount --move /proc /mnt/newroot/proc || mount -t proc proc /mnt/newroot/proc
mount --move /sys  /mnt/newroot/sys  || mount -t sysfs sysfs /mnt/newroot/sys
mount --move /dev  /mnt/newroot/dev  || mount -t devtmpfs devtmpfs /mnt/newroot/dev
mount --move /run  /mnt/newroot/run  || mount -t tmpfs tmpfs /mnt/newroot/run
mount -t devpts -o gid=5,mode=620,noexec,nosuid devpts /mnt/newroot/dev/pts

echo "Environment prepared."
sleep 3
echo "Handing over control to systemd...\n"

exec chroot /mnt/newroot /lib/systemd/systemd || \
     exec chroot /mnt/newroot /sbin/init || {
         echo "CRITICAL ERROR: Failed to start systemd"
         exec /bin/sh
     }

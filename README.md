# Atomic Green

Atomic Green is a lightweight, custom preinit script that transforms a standard systemd-based Linux installation into an **immutable root system** using OverlayFS.

- The base root filesystem (lower layer) remains protected and read-only in practice.
- User changes and configurations are persisted on a separate data partition (upper/work layers).
- Full reset to pristine state is possible by clearing the data partition layers.
- No initramfs/initrd required (direct kernel boot).
- Designed for post-install application (e.g., from Live USB/CD after normal installation).
- Generic and distro-agnostic: works on any systemd-based Linux with kernel overlayfs support (tested on Ubuntu 20.04/22.04/24.04 Minimal and Desktop, Debian, etc.).

## Features

- Immutable base root with optional persistence.
- Dual boot support: standard entry (normal writable root) + dedicated immutable entry.
- Robust partition detection: prefers explicit UUID via GRUB cmdline (recommended), with fallback to LABEL=DATA.
- Professional boot console output with progress steps and delays for readability.
- Easy manual reset to factory/pristine state.

## Disk Partition Requirements

You must manually partition the disk with **exactly three partitions** during installation:

1. **EFI System Partition**:
   - Size: 512 MiB–1 GiB
   - Type: FAT32
   - Mount point: `/boot/efi`
   - No special label required (GRUB handles it automatically).

2. **Root Base Partition** (lowerdir — the protected system):
   - Size: As needed (e.g., 10–30 GiB for Desktop)
   - Type: ext4
   - **Label: ROOT-BASE** (mandatory — set during partitioning or with `e2label`).

3. **Data/Persistence Partition** (upperdir + workdir):
   - Size: Remaining space (or as desired)
   - Type: ext4
   - **Label: DATA** (recommended for fallback) **and/or note its UUID** (required for robust setup).

**How to get/set labels and UUIDs** (run these commands during Live USB setup, before or after formatting):

```bash
# List all partitions and their labels/UUIDs
sudo blkid

# Example output line for data partition:
/dev/sda3: LABEL="DATA" UUID="12345678-1234-1234-1234-123456789abc" TYPE="ext4"

# Set label (if not set during partitioning)
sudo e2label /dev/sda3 DATA          # for data partition
sudo e2label /dev/sda2 ROOT-BASE     # for root base

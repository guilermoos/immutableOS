# Atomic Green

Atomic Green is a lightweight, custom preinit script that transforms a standard systemd-based Linux installation into an **immutable root system** using OverlayFS.

- The base root filesystem remains read-only (protected).
- Changes are persisted on a separate data partition (optional reset to pristine state).
- No initramfs required.
- Designed for easy post-install application (via LiveCD/USB).
- Generic: works on any systemd distro with overlayfs support (tested on Ubuntu/Debian derivatives).

## Features

- Immutable base root with optional persistence.
- Dual boot support: normal mode + immutable mode.
- Explicit configuration via GRUB parameters (UUID preferred for robustness).
- Clean, professional boot messages with progress indication.
- Easy reset: delete `/upper` and `/work` on the data partition to restore pristine state.

## Requirements

- Systemd-based Linux distribution.
- Kernel with built-in overlayfs support (most modern kernels).
- Disk layout with three partitions:
  1. EFI (FAT32, mounted at `/boot/efi`).
  2. Root base (ext4, labeled `ROOT-BASE`).
  3. Data/persistence (ext4, labeled `DATA` or identified by UUID).

## Installation (Post-Install via Live USB)

1. Boot from any Live USB of your distro.
2. Install the system normally (select manual partitioning and create the three partitions above).
3. **Do not reboot yet**. Open a terminal and mount the installed root:

   ```bash
   sudo mount /dev/sdXY /mnt                  # sdXY = root-base partition
   sudo mount /dev/sdXZ /mnt/boot/efi         # sdXZ = EFI partition
   for d in dev proc sys run; do sudo mount --bind /$d /mnt/$d; done

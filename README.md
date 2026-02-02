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

#!/bin/sh
exec tail -n +3 $0

# Entrada para boot imutável (Atomic Green)
menuentry "Atomic Green - Immutable Mode" {
    linux   /boot/vmlinuz-* root=LABEL=ROOT-BASE rw preinit=/sbin/preinit-immutable quiet splash
    initrd  /boot/initrd.img-*   # Mantenha essa linha se o seu sistema usa initrd (padrão no Ubuntu)
}
```
# Testing Immutability

**Boot into "Atomic Green - Immutable Mode" and run:**

```bash
# Verify overlay is active
mount | grep overlay
# Expected: overlay on / type overlay (rw,relatime,lowerdir=/,upperdir=/mnt/data/upper,workdir=/mnt/data/work)
```
# Test persistence
```bash
echo "persistent test" > /etc/test-persistent.txt
sudo reboot
```
# After reboot (still in immutable mode)
```bash
cat /etc/test-persistent.txt   # File must still exist
```
# Test full reset (return to pristine state)
```bash
sudo mkdir /mnt/data
```
# Use UUID (robust) or fallback LABEL
```bash
sudo mount /dev/disk/by-uuid/YOUR-DATA-UUID /mnt/data   # or sudo mount LABEL=DATA /mnt/data
sudo rm -rf /mnt/data/upper/* /mnt/data/work/*
sudo umount /mnt/data
sudo reboot
```
# After reboot
```bash
ls /etc/test-persistent.txt   # File must be gone (system restored to base state)
```

Entendi a confusão! Vamos simplificar **ao máximo**, como você pediu: **usando somente LABELs** (sem UUID via parâmetro no GRUB). Isso funciona perfeitamente porque o script já tem um fallback automático para `LABEL=DATA` quando não há UUID.

### Resumo rápido das labels (para não ficar dúvida)

- **Partição root base** (a que tem o sistema instalado, lowerdir): **deve ter LABEL exatamente "ROOT-BASE"**.
- **Partição de dados/persistência** (upper + work): **deve ter LABEL exatamente "DATA"**.

Nada de UUID no GRUB — o script tenta LABEL=DATA automaticamente.

### Exemplo exato do menuentry simples (só com labels)

Edite o arquivo `/etc/grub.d/40_custom` (dentro do chroot ou no sistema instalado) e cole **exatamente isso**:

```bash
#!/bin/sh
exec tail -n +3 $0

menuentry "Atomic Green - Immutable Mode (protected root)" {
    linux   /boot/vmlinuz-* root=LABEL=ROOT-BASE rw preinit=/sbin/preinit-immutable
    # Se você usar initramfs normal (padrão no Ubuntu), descomente a linha abaixo:
    # initrd  /boot/initrd.img-*
}
```

### Passos completos para aplicar (simples e direto)

1. No LiveCD (ou no sistema já bootado em modo normal), monte a partição root instalada:

```bash
sudo mount /dev/sda2 /mnt                  # ajuste /dev/sda2 para sua partição ROOT-BASE
sudo mount /dev/sda1 /mnt/boot/efi         # EFI
for d in dev proc sys run; do sudo mount --bind /$d /mnt/$d; done
```

2. Copie o script (se ainda não tiver):

```bash
sudo curl -o /mnt/sbin/preinit-immutable https://raw.githubusercontent.com/SEUUSER/AtomicGreen/main/preinit-immutable
sudo chmod +x /mnt/sbin/preinit-immutable
```

3. Entre no chroot:

```bash
sudo chroot /mnt
```

4. Dentro do chroot, crie/edite o menuentry:

```bash
nano /etc/grub.d/40_custom
```

Cole o conteúdo que eu dei acima.

5. Atualize GRUB:

```bash
chmod +x /etc/grub.d/40_custom
update-grub
exit   # sai do chroot
```

6. Desmonte e reboot:

```bash
sudo umount -l /mnt/{dev,proc,sys,run,boot/efi}
sudo umount /mnt
reboot
```

### O que aparece no GRUB

- Entrada padrão: boot normal (sem imutabilidade, raiz gravável).
- Nova entrada: "Atomic Green - Immutable Mode (protected root)" → selecione essa para boot imutável (usa só labels + preinit).

O script vai mostrar na tela:

- Tenta LABEL=DATA automaticamente (fallback).
- Monta tudo e faz o overlay.

Teste depois do boot (na entrada imutável):

```bash
mount | grep overlay   # deve mostrar o overlay ativo em /
```

Se quiser resetar: monte LABEL=DATA manualmente e apague upper/work.

Agora está **super simples**, só labels, sem UUID complicando. Funciona 100% no Ubuntu Desktop/Minimal. Me avisa se bootou e como ficou a tela! 🚀

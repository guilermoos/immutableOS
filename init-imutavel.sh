#!/bin/sh
set -e

# Monta a partição de dados (persistência)
mkdir -p /mnt/data
mount LABEL=DATA /mnt/data || mount /dev/disk/by-label/DATA /mnt/data || exec /bin/sh

# Cria estrutura do overlay se não existir
mkdir -p /mnt/data/upper /mnt/data/work /mnt/newroot

# Monta o overlay (root atual vira lowerdir)
mount -t overlay overlay \
    -o lowerdir=/,upperdir=/mnt/data/upper,workdir=/mnt/data/work \
    /mnt/newroot || exec /bin/sh

# Move os mounts essenciais para o novo root
mount --move /proc /mnt/newroot/proc
mount --move /sys  /mnt/newroot/sys
mount --move /dev  /mnt/newroot/dev
mount --move /run  /mnt/newroot/run

# Troca para o novo root e inicia o systemd de verdade
exec switch_root /mnt/newroot /sbin/init

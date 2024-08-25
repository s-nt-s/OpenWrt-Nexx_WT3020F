#!/bin/sh
# Montar USB
if [ -f /etc/config/fstab ]; then
if ! grep -q '/dev/sda1' /etc/config/fstab; then
cat << EOF_cat >> /etc/config/fstab
config mount
  option device '/dev/sda1'
  option enabled '1'
  option target '/mnt/usb'
  option enabled_fsck '1'

config swap
  option device '/dev/sda2'
  option enabled '1'
EOF_cat
else
  sed "s/option\s*enabled\s*'0'/option\tenabled\t'1'/g" -i /etc/config/fstab
  sed "s/'\/mnt\/sda2'/'\/mnt\/usb'\n\toption\tenabled_fsck\t'1'/" -i /etc/config/fstab
fi
fi
mkdir -p /mnt/usb
ln -s /mnt/usb /root/usb
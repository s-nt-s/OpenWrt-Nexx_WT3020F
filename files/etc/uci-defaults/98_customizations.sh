#!/bin/sh
# Cambiar IP
sed 's/\b192\.168\.1\.1\b/192.168.8.1/g' -i /etc/config/network
# Cambiar el SSID de la wifi
sed "s/option ssid 'OpenWrt'/option ssid 'NEXX'/" -i /etc/config/wireless
# Borrar banner
rm /etc/banner
# Deshabilitar nodogsplash
if [ -f /etc/config/nodogsplash ]; then
  sed 's/option enabled 1/option enabled 0/' -i /etc/config/nodogsplash
fi
# Montar USB
if [ -f /etc/config/fstab ]; then
if ! grep -q '5c88f9ec-b33e-4801-af3e-1822c1acbb2f' /etc/config/fstab; then
cat << EOF_cat >> /etc/config/fstab
config swap
	option uuid '5c88f9ec-b33e-4801-af3e-1822c1acbb2f'
	option enabled '1'

config mount
	option uuid 'af184e4d-707f-4d70-bad6-9888dc2f42a7'
	option enabled '1'
	option target '/mnt/usb'
	option enabled_fsck '1'
EOF_cat
else
  sed "s/option\s*enabled\s*'0'/option\tenabled\t'1'/g" -i /etc/config/fstab
  sed "s/'\/mnt\/sda2'/'\/mnt\/usb'\n\toption\tenabled_fsck\t'1'/" -i /etc/config/fstab
fi
fi
mkdir -p /mnt/usb
ln -s /mnt/usb /root/usb
# Hacer que las sesiones screen hagan login en sh (asi podremos usar los alias)
echo "screen sh -l" >> /etc/screenrc

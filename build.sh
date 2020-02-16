#!/bin/bash
cd "$(dirname "$0")"

if [ -f ~/.ssh/nexx.pub ]; then
  cp ~/.ssh/nexx.pub files/etc/dropbear/authorized_keys
  sed 's/ \S*@\S*\s*$/ my@pc/' -i files/etc/dropbear/authorized_keys
fi

if [ -f ./env.sh ]; then
source ./env.sh
cat << EOF_cat > files/etc/uci-defaults/98_pass.sh
#!/bin/sh
# Darle seguridad a la wifi
sed "s/option encryption 'none'/option encryption 'psk2'\n\toption key '${WIFI_PASS}'/" -i /etc/config/wireless
sed "/option disabled '1'/d" -i /etc/config/wireless
# Poner la pass a root
echo "root:${ROOT_PASS}" | chpasswd -c MD5
EOF_cat
fi

cd openwrt*/
make image PROFILE="wt3020-8M" PACKAGES="aircrack-ng airmon-ng kmod-usb-storage kmod-fs-ext4 kmod-usb-storage-extras block-mount kmod-scsi-core screen reaver nano uhttpd uhttpd-mod-ubus libiwinfo-lua luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap nodogsplash tcpdump luci-app-opkg luci-proto-ipv6 luci-proto-ppp luci rpcd-mod-rrdns luci shadow-chpasswd ipset" FILES=files/ BIN_DIR="$(realpath ..)/bin"

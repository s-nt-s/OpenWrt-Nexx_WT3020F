#!/bin/sh
# Cambiar IP
sed 's/\b192\.168\.1\.1\b/192.168.8.1/g' -i /etc/config/network
# Cambiar el SSID de la wifi
sed "s/option ssid 'OpenWrt'/option ssid 'NEXX'/" -i /etc/config/wireless
# Borrar banner
rm /etc/banner
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
# Crear wifi de invitados
uci set network.guest='interface'
uci set network.guest.proto='static'
uci set network.guest.ipaddr='192.168.3.1'
uci set network.guest.netmask='255.255.255.0'
uci set network.guest.ifname='br-lan'
uci set network.guest.type='bridge'
uci set dhcp.guest='dhcp'
uci set dhcp.guest.interface='guest'
uci set dhcp.guest.start='100'
uci set dhcp.guest.leasetime='12h'
uci set dhcp.guest.limit='150'
uci set firewall.guest='zone'
uci set firewall.guest.name='guest'
uci set firewall.guest.network='guest'
uci set firewall.guest.forward='REJECT'
uci set firewall.guest.output='ACCEPT'
uci set firewall.guest.input='REJECT'
uci set firewall.guest_fwd='forwarding'
uci set firewall.guest_fwd.src='guest'
uci set firewall.guest_fwd.dest='wan'
uci set firewall.guest_dhcp='rule'
uci set firewall.guest_dhcp.name='guest_DHCP'
uci set firewall.guest_dhcp.src='guest'
uci set firewall.guest_dhcp.target='ACCEPT'
uci set firewall.guest_dhcp.proto='udp'
uci set firewall.guest_dhcp.dest_port='67-68'
uci set firewall.guest_dns='rule'
uci set firewall.guest_dns.name='guest_DNS'
uci set firewall.guest_dns.src='guest'
uci set firewall.guest_dns.target='ACCEPT'
uci set firewall.guest_dns.proto='tcpudp'
uci set firewall.guest_dns.dest_port='53'
uci set wireless.wifinet1='wifi-iface'
uci set wireless.wifinet1.device='radio0'
uci set wireless.wifinet1.mode='ap'
uci set wireless.wifinet1.ssid='FreeWifi'
uci set wireless.wifinet1.encryption='none'
uci set wireless.wifinet1.isolate='1'
uci set wireless.wifinet1.network='guest'
uci commit network
uci commit dhcp
uci commit firewall
uci commit wireless
service network reload
service dnsmasq restart
service firewall restart
# Deshabilitar nodogsplash
if [ -f /etc/config/nodogsplash ]; then
  #sed 's/option enabled 1/option enabled 0/' -i /etc/config/nodogsplash
  sed "s/option gatewayinterface 'br-lan'/option gatewayinterface 'br-guest' # 'br-lan'/" -i /etc/config/nodogsplash
  sed "s/option gatewayname 'OpenWrt Nodogsplash'/option gatewayname 'FreeWifi'/" -i /etc/config/nodogsplash
  sed "s/list authenticated_users 'allow all'/#list authenticated_users 'allow all'/" -i /etc/config/nodogsplash
  sed -E "s/#(list authenticated_users 'allow .*(53|80|443))/\1/" -i /etc/config/nodogsplash
  sed -E "s/(list users_to_router 'allow .*(22|23|80|443))/#\1/" -i /etc/config/nodogsplash
fi

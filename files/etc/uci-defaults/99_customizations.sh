#!/bin/sh
# Cambiar IP
sed 's/\b192\.168\.1\.1\b/192.168.8.1/g' -i /etc/config/network

# Cambiar el SSID de la wifi
sed "s/option ssid 'OpenWrt'/option ssid 'NEXX'/" -i /etc/config/wireless

# Borrar banner
rm /etc/banner

# Hacer que las sesiones screen hagan login en sh (asi podremos usar los alias)
echo "screen sh -l" >> /etc/screenrc

# Crear wifi de invitados
# https://openwrt.org/docs/guide-user/network/wifi/guestwifi/guest-wlan
uci -q delete network.guest_dev
uci set network.guest_dev="device"
uci set network.guest_dev.type="bridge"
uci set network.guest_dev.name="br-guest"
uci -q delete network.guest
uci set network.guest='interface'
uci set network.guest.proto='static'
uci set network.guest.device='br-guest'
uci set network.guest.ipaddr='192.168.3.1'
uci set network.guest.netmask='255.255.255.0'
uci -q delete wireless.guest
uci set wireless.guest='wifi-iface'
uci set wireless.guest.device='radio0'
uci set wireless.guest.mode='ap'
uci set wireless.guest.network='guest'
uci set wireless.guest.ssid='FreeWifi'
uci set wireless.guest.encryption='none'
uci set wireless.guest.isolate='1'
uci set wireless.guest.disabled='1'
#uci set wireless.guest.disabled='0'
uci -q delete dhcp.guest
uci set dhcp.guest='dhcp'
uci set dhcp.guest.interface='guest'
uci set dhcp.guest.start='100'
uci set dhcp.guest.limit='150'
uci set dhcp.guest.leasetime='1h'
uci -q delete firewall.guest
uci set firewall.guest="zone"
uci set firewall.guest.name="guest"
uci set firewall.guest.network="guest"
uci set firewall.guest.input="REJECT"
uci set firewall.guest.output="ACCEPT"
uci set firewall.guest.forward="REJECT"
uci -q delete firewall.guest_dns
uci set firewall.guest_dns="rule"
uci set firewall.guest_dns.name="Allow-DNS-Guest"
uci set firewall.guest_dns.src="guest"
uci set firewall.guest_dns.dest_port="53"
uci set firewall.guest_dns.proto="tcp udp"
uci set firewall.guest_dns.target="ACCEPT"
uci -q delete firewall.guest_dhcp
uci set firewall.guest_dhcp="rule"
uci set firewall.guest_dhcp.name="Allow-DHCP-Guest"
uci set firewall.guest_dhcp.src="guest"
uci set firewall.guest_dhcp.dest_port="67"
uci set firewall.guest_dhcp.proto="udp"
uci set firewall.guest_dhcp.family="ipv4"
uci set firewall.guest_dhcp.target="ACCEPT"
#uci -q delete firewall.guest_wan
#uci set firewall.guest_wan="forwarding"
#uci set firewall.guest_wan.src="guest"
#uci set firewall.guest_wan.dest="wan"
#uci -q delete firewall.guest_wan
uci -q delete firewall.guest_fwd
uci set firewall.guest_fwd="rule"
uci set firewall.guest_fwd.name="Allow-HTTP/HTTPS/XMPP-Guest-Forward"
uci set firewall.guest_fwd.src="guest"
uci set firewall.guest_fwd.dest="wan"
uci set firewall.guest_fwd.dest_ip="!192.168.1.1/24"
uci add_list firewall.guest_fwd.dest_port="80"
uci add_list firewall.guest_fwd.dest_port="443"
uci add_list firewall.guest_fwd.dest_port="5222"
uci add_list firewall.guest_fwd.dest_port="5223"
uci set firewall.guest_fwd.proto="tcp"
uci set firewall.guest_fwd.target="ACCEPT"
# Acceder al SSH y HTTP desde el router ISP
uci add firewall redirect
uci set firewall.@redirect[-1].target='DNAT'
uci set firewall.@redirect[-1].name='SSH'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='22'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.8.1'
uci set firewall.@redirect[-1].dest_port='22'
uci add firewall redirect
uci set firewall.@redirect[-1].target='DNAT'
uci set firewall.@redirect[-1].name='HTTP'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='80'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.8.1'
uci set firewall.@redirect[-1].dest_port='80'
uci add firewall redirect
uci set firewall.@redirect[-1].target='DNAT'
uci set firewall.@redirect[-1].name='PRINTER'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='9100'
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].dest_ip='192.168.8.1'
uci set firewall.@redirect[-1].dest_port='9100'

uci commit network
uci commit dhcp
uci commit firewall
uci commit wireless
service network reload
service dnsmasq restart
service firewall restart


if [ -f /usr/bin/getip.sh ]; then
  mv /usr/bin/getip.sh /usr/bin/getip
  chmod 755 /usr/bin/getip
fi

function my_chmod {
  if [ -f "$2" ]; then
    chmod "$1" "$2"
  elif [ -d "$fl" ]; then
    chmod "$1" -R "$2"
  fi
}
my_chmod 600 /etc/dropbear
my_chmod 600 /etc/ssmtp
my_chmod 600 /etc/msmtprc
my_chmod 644 /etc/aliases

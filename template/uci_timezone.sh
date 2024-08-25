#!/bin/sh
if [ -f /usr/share/ucode/luci/zoneinfo.uc ]; then
  MY_TZ=$(grep "REPLAE_WITH_TZ_NAME" /usr/share/ucode/luci/zoneinfo.uc | cut -d"'" -f4)
  if [ ! -z "$MY_TZ" ]; then
    uci set system.@system[0].zonename='REPLAE_WITH_TZ_NAME'
    uci set system.@system[0].timezone="${MY_TZ}"
    uci commit system
  fi
fi
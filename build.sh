#!/bin/bash
set -e

cd "$(dirname "$0")"

function exe {
  echo "\$ $@"
  $@
}
function fmt_json {
  if [ -f "$1" ]; then
    cat "$1" | jq -r '.' > "$1.tmp"
    mv "$1.tmp" "$1"
  fi
}

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
echo -e "${ROOT_PASS}\n${ROOT_PASS}" | passwd
EOF_cat
fi
if [ -f /etc/timezone ]; then
MY_TZ_NAME=$(cat /etc/timezone)
if [ ! -z "$MY_TZ_NAME" ]; then
cat << EOF_cat > files/etc/uci-defaults/97_timezone.sh
#!/bin/sh
if [ -f /usr/lib/lua/luci/sys/zoneinfo/tzdata.lua ]; then
  MY_TZ=\$(grep "{\\s*'${MY_TZ_NAME}',\\s*" /usr/lib/lua/luci/sys/zoneinfo/tzdata.lua | sed "s/.*,\\s*'//" | sed "s/'.*//")
  if [ ! -z "\$MY_TZ" ]; then
    uci set system.@system[0].zonename='${MY_TZ_NAME}'
    uci set system.@system[0].timezone="\${MY_TZ}"
    uci commit system
  fi
fi
EOF_cat
fi
fi

PCKS=$(sed -e '/^\s*$/d' -e '/^#/d' packages.txt | cut -d' ' -f1 | sort | uniq | paste -sd " " -)

cd openwrt*/
if [ "$1" == "clean" ]; then
    make clean
    echo ""
fi
TRG="$(realpath ..)/bin"
if [ -d "$TRG" ]; then
  rm -R "$TRG"
fi
mkdir -p "$TRG"
make image PROFILE="nexx_wt3020-8m" PACKAGES="$PCKS" FILES=files/ BIN_DIR="$TRG"

cd ..

fmt_json bin/profiles.json
./diff.sh > bin/README.md

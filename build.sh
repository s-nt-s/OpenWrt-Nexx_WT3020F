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
fi

rm -rf files/etc/uci-defaults/8*.sh

if [ ! -z "$ROOT_PASS" ]; then
sed "s|REPLACE_WITH_ROOT_PASS|$ROOT_PASS|g" \
  template/uci_root.sh > files/etc/uci-defaults/80_root.sh
fi

if [ ! -z "$WIFI_PASS" ]; then
sed "s|REPLACE_WITH_WIFI_PASS|$WIFI_PASS|g" \
  template/uci_wifi.sh > files/etc/uci-defaults/81_wifi.sh
fi


if [ -f /etc/timezone ]; then
MY_TZ_NAME=$(cat /etc/timezone)
if [ ! -z "$MY_TZ_NAME" ]; then
sed "s|REPLAE_WITH_TZ_NAME|$MY_TZ_NAME|g" \
  template/uci_timezone.sh > files/etc/uci-defaults/82_timezone.sh
fi
fi

if [ ! -z "$SRV_SYSLOG" ]; then
sed "s|REPLACE_WITH_SRV_SYSLOG|$SRV_SYSLOG|g" \
  template/uci_syslog.sh > files/etc/uci-defaults/83_log_ip.sh
fi

if [ ! -z "$MOUNT_USB" ]; then
cp template/uci_mount.sh files/etc/uci-defaults/89_mount.sh
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

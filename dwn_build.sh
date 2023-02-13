#!/bin/bash
set -e

cd "$(dirname "$0")"
ROOT_URL="https://openwrt.org/toh/hwdata/nexx/nexx_wt3020f"
if [ ! -z "$1" ]; then
  ROOT_URL="$1"
fi
echo "$ROOT_URL"
BIN_URL=$(lynx -listonly -dump "$ROOT_URL" | grep 'releases' | grep 'squashfs-factory.bin' | sed 's/.* //' | sort | tail -n 1)
echo "$BIN_URL"
FLD_URL=$(echo "$BIN_URL" | sed 's/[^\/]*$//' )
echo "$FLD_URL"
BLD_URL=$(lynx -listonly -dump "$FLD_URL" | grep 'openwrt-imagebuilder' | grep "tar.xz" | sed 's/.* //')
echo "$BLD_URL"
rm -Rf openwrt-imagebuilder* 2> /dev/null
wget "$BLD_URL"
tar xf *.tar.xz
if [ -d files ]; then
  cd openwrt*/
  ln -s ../files
fi

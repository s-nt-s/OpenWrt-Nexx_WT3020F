#!/bin/bash
cd "$(dirname "$0")"
ROOT_URL="https://openwrt.org/toh/hwdata/nexx/nexx_wt3020f"
if [ ! -z "$1" ]; then
  ROOT_URL="$1"
fi
BIN_URL=$(lynx -listonly -dump "$ROOT_URL" | grep 'releases' | grep 'squashfs-factory.bin' | sed 's/.* //' | sort | tail -n 1)
FLD_URL=$(echo "$BIN_URL" | sed 's/[^\/]*$//' )
MNF_URL=$(lynx -listonly -dump "$FLD_URL" | grep 'openwrt' | grep ".manifest" | sed 's/.* //')
ARR_OFI=( $(curl -s "$MNF_URL" | cut -d' ' -f1 | sort | uniq) )
ARR_CUS=( $(cat bin/*.manifest | cut -d' ' -f1 | sort | uniq) )
ARR_NEW=( $(comm -13 <(printf '%s\n' "${ARR_OFI[@]}") <(printf '%s\n' "${ARR_CUS[@]}")) )
ARR_REM=( $(comm -13 <(printf '%s\n' "${ARR_CUS[@]}") <(printf '%s\n' "${ARR_OFI[@]}")) )

VRS=$(echo "$MNF_URL" | rev | cut -d'/' -f 1 | rev | sed 's/\.[^\.]*$//')
echo "# Cambios con respecto a [$VRS]($MNF_URL)"
echo ""
echo "## Paquetes eliminados"
echo ""
if [ "${#ARR_REM[@]}" -eq 0 ]; then
echo "No se ha eliminado ningún paquete"
else
for i in "${ARR_REM[@]}"; do
    echo "* $i"
done
fi
echo ""
echo "## Paquetes añadidos"
echo ""
if [ "${#ARR_NEW[@]}" -eq 0 ]; then
echo "No se ha añadido ningún paquete"
else
for i in "${ARR_NEW[@]}"; do
    echo "* $i"
done
fi

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
echo "########"
echo "# A = $MNF_URL"
echo "# B = $(ls bin/*.manifest | cut -d'/' -f2)"
echo "# + = Esta en B pero no en A"
echo "# - = Esta en A pero no en B"
echo "########"

ARR_NEW=( $(comm -13 <(printf '%s\n' "${ARR_OFI[@]}") <(printf '%s\n' "${ARR_CUS[@]}")) )
ARR_REM=( $(comm -13 <(printf '%s\n' "${ARR_CUS[@]}") <(printf '%s\n' "${ARR_OFI[@]}")) )

for c in $(sort <(for f in "${ARR_NEW[@]}" ; do echo "$f" ; done) <(for f in "${ARR_REM[@]}" ; do echo "$f" ; done)); do
    for i in "${ARR_NEW[@]}"; do
        if [ "$i" == "$c" ] ; then
            echo "+ $c"
        fi
    done
    for i in "${ARR_REM[@]}"; do
        if [ "$i" == "$c" ] ; then
            echo "- $c"
        fi
    done
done



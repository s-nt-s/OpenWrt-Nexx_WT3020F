[`Nexx WT3020F` es un mini-router que soporta `OpenWrt`](https://openwrt.org/toh/nexx/wt3020). Pero como todo, al implementarlo puede dar problemas:

## Problemas

### Falta de espacio

Para paliar la falta de espacio hay varias opciones:

* Si solo queremos espacio para datos (no para instalar paquetes), bastaría con montar una memoria USB
* Si necesitamos espacio para instalar paquetes podemos:
  * hacer [`extroot`](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
  * [rehacer la imagen de `OpenWrt`](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) antes de instalarla para aprovechar al máximo el espacio disponible

Desinstalar paquetes que venían por defecto no es una opción, ya que no libera espacio e incluso puede llegar a ser contraproducente. Ver:

* [reddit.com - What can i safely remove from this list to save space?](https://www.reddit.com/r/openwrt/comments/9zyn09/what_can_i_safely_remove_from_this_list_to_save/ead6b8o/)
* [openwrt.org - No space left on device](https://openwrt.org/faq/no_space_left_on_device)

También hay que tener en cuenta que hacer `extroot` tiene la desventaja
de que el router se vuelve dependiente del usb que estamos usando,
si lo queremos cambiar ya no es tan trivial,
si lo necesitamos para otra cosa hay que hacerle una copia para revertirla luego,
y mientras tenemos el router parado porque sin el usb pierde la configuración
y paquetes que hemos metido, etc


### Algo se rompe y pierdes la configuración

En cuanto que algo que algo se rompa las soluciones son:

* Si lo que se ha roto no impide el acceso al router:
  * Volver a configurar lo que acabas de tocar como estaba antes
  * Restablecer una copia de seguridad de la configuración anterior
* Si lo que se ha roto si que impide el acceso al router:
  * Hacer un reseteo de fabrica y reconfigurar todo desde el principio

### Así que...

Así que finalmente, creo que lo mejor es hacer una imagen personalizada que
ahorre todo el espacio que podamos y lleve de serie los paquetes que de otro
modo habríamos instalado a mano. Y para lo demás montar un usb para datos
y memoria swap.

<hr/>

## Objetivo

Crear una imagen `OpenWrt` para `Nexx WT3020`:

* con [menos paquetes](https://openwrt.org/faq/which_packages_can_i_safely_remove_to_save_space)
* <s>con los `css`, `js` y `html` comprimidos</s> (ya no hace falta, viene por defecto)
* con algunos paquetes extra, por ejemplo `nano` y `aircrack`
* con la ip cambiada a `192.168.8.1` para que coincida con la de la pegatina del router y para que no colisione con otros router
* con la contraseña de `root` habilitada
* y preparado para montar un USB con una partición paras swap y otra para datos

## Preparar entorno

Siguiendo [openwrt.org - imagebuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

```console
$ sudo apt-get install build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python
```

Navegando por openwrt.org:

  * [nexx_wt3020f](https://openwrt.org/toh/hwdata/nexx/nexx_wt3020f)
  * [19.07.0 - Firmware OpenWrt Install](http://downloads.openwrt.org/releases/19.07.0/targets/ramips/mt7620/openwrt-19.07.0-ramips-mt7620-wt3020-8M-squashfs-factory.bin)
  * [19.07.0 - Carpeta de ramips/mt7620](http://downloads.openwrt.org/releases/19.07.0/targets/ramips/mt7620/)
  * [19.07.0 - imagebuilder](http://downloads.openwrt.org/releases/19.07.0/targets/ramips/mt7620/openwrt-imagebuilder-19.07.0-ramips-mt7620.Linux-x86_64.tar.xz)

```console
$ wget "http://downloads.openwrt.org/releases/19.07.0/targets/ramips/mt7620/openwrt-imagebuilder-19.07.0-ramips-mt7620.Linux-x86_64.tar.xz"
$ tar xf *.tar.xz
$ cd openwrt*/
```

o lo que es lo mismo, pero automatizado:

```bash
#!/bin/bash
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
rm -R openwrt-imagebuilder* 2> /dev/null
wget "$BLD_URL"
tar xf *.tar.xz
if [ -d files ]; then
  cd openwrt*/
  ln -s ../files
fi
```

Haciendo `make info` vemos que el `profile` que nos corresponde es `wt3020-8M`

```console
$ make info
...
wt3020-8M:
    Nexx WT3020 (8MB)
    Packages: kmod-usb2 kmod-usb-ohci
    hasImageMetadata: 1
    SupportedDevices: wt3020-8M wt3020
...
```

Creamos los ficheros que queremos que se añadan a la imagen:

```console
$ mkdir -p files/etc/profile.d/
$ echo 'alias getip="wget -q ifconfig.me -O -"' > files/etc/profile.d/alias.sh
$ echo 'export EDITOR="nano"' > files/etc/profile.d/export.sh
$ touch files/etc/banner
$ mkdir -p files/etc/dropbear/
$ cp ~/.ssh/nexx.pub files/etc/dropbear/authorized_keys
```

Usando la misma funcionalidad y [UCI defaults](https://openwrt.org/docs/guide-developer/uci-defaults)
creamos el scripts que cambiaran la configuración por defecto

```console
$ mkdir -p files/etc/uci-defaults/
$ cat << EOF_cat > files/etc/uci-defaults/99_customizations.sh
#!/bin/sh
# Cambiar IP
sed 's/\b192\.168\.1\.1\b/192.168.8.1/g' -i /etc/config/network
# Cambiar el SSID de la wifi y darle seguridad
sed "s/option ssid 'OpenWrt'/option ssid 'NEXX'/" -i /etc
sed "s/option encryption 'none'/option encryption 'psk2'\n\toption key 'la_pass_de_la_wifi'/" -i /etc/config/wireless/config/wireless
# Borrar banner
rm /etc/banner
# Deshabilitar nodogsplash
if [ -f /etc/config/nodogsplash ]; then
  sed 's/option enabled 1/option enabled 0/' -i /etc/config/nodogsplash
fi
echo "root:mi_contraseña_para_nexx" | chpasswd -c MD5
opkg remove shadow-chpasswd
EOF_cat
```

## Crear imagen

```console
$ make image PROFILE="wt3020-8M" PACKAGES="aircrack-ng airmon-ng kmod-usb-storage kmod-fs-ext4 kmod-usb-storage-extras block-mount kmod-scsi-core screen reaver nano uhttpd uhttpd-mod-ubus libiwinfo-lua luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap nodogsplash tcpdump luci-app-opkg luci-proto-ipv6 luci-proto-ppp luci rpcd-mod-rrdns luci shadow-chpasswd ipset" FILES=files/ BIN_DIR="$(realpath ..)"
```

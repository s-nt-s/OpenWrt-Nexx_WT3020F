# Objetvio

Crear una imagen `OpenWrt` para el router [`Nexx WT3020F`](https://wikidevi.wi-cat.ru/Nexx_WT3020) con los paquetes básicos,
ahorrando el máximo espacio y evitando tener que hacer [`extroot`](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)

## ¿Por qué?

* Tal como esta hecho `OpenWrt` es mejor crear una imagen con los paquetes deseados,
que quemar [la imagen por defecto](https://openwrt.org/toh/nexx/wt3020) e instalar/desinstalar
paquetes a posteriori. Ver:
    * [reddit.com - What can i safely remove from this list to save space?](https://www.reddit.com/r/openwrt/comments/9zyn09/what_can_i_safely_remove_from_this_list_to_save/ead6b8o/)
    * [openwrt.org - No space left on device](https://openwrt.org/faq/no_space_left_on_device)
* Hacer [`extroot`](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration)
provoca que necesitemos dedicar permanentemente un pendrive al router. Prefiero tener
el sistema enteramente en el router, y usar el usb solo para almacenamiento de datos y memoria `swap` de manera que sea fácil prescindir de él o sustituirlo por otro.

# Realización

## Guía rápida

* Usar [`image builder`](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)
* [Eliminar paquetes](https://openwrt.org/faq/which_packages_can_i_safely_remove_to_save_space) no deseados
* <s>Comprimir los `css`, `js` y `html`</s> (ya no hace falta, viene por defecto)
* Instalar paquetes extra, por ejemplo `nano` y `aircrack`
* Cambiar la ip a `192.168.8.1` para que coincida con la de la pegatina del router y para que no colisione con otros routers
* Habilitar la contraseña `root`
* Automontar USB con una partición para `swap` y otra para datos `ext4` (opcional)
* Añadir `alias` y `prompt` al gusto
* Añadir un comando para obtener la ip pública
* Poner el router en la misma zona horaria que la del ordenador donde se esta generando la imagen
* Configurar redes inalámbricas:
    * Poner contraseña a la red principal
    * Crear una red para invitados protegida con `nodogsplash`

## Preparar entorno

Siguiendo [openwrt.org - imagebuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder)

```console
$ sudo apt-get install build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python
```

Navegando por openwrt.org:

* [nexx_wt3020f](https://openwrt.org/toh/hwdata/nexx/nexx_wt3020f)
* [23.05.4 - Firmware OpenWrt Install](https://downloads.openwrt.org/releases/23.05.4/targets/ramips/mt7620/openwrt-23.05.4-ramips-mt7620-nexx_wt3020-8m-squashfs-factory.bin)
* [23.05.4 - Carpeta de ramips/mt7620](https://downloads.openwrt.org/releases/23.05.4/targets/ramips/mt7620/)
* [23.05.4 - imagebuilder](https://downloads.openwrt.org/releases/23.05.4/targets/ramips/mt7620/openwrt-imagebuilder-23.05.4-ramips-mt7620.Linux-x86_64.tar.xz)

```console
$ wget "https://downloads.openwrt.org/releases/23.05.4/targets/ramips/mt7620/openwrt-imagebuilder-23.05.4-ramips-mt7620.Linux-x86_64.tar.xz"
$ tar xf *.tar.xz
```

o lo que es lo mismo, pero automatizado, [`./dwn_build.sh`](dwn_build.sh)

Haciendo `make info` vemos que el `profile` que nos corresponde es `wt3020-8M`

```console
$ make info
...
nexx_wt3020-8m:
    Nexx WT3020 8M
    Packages: kmod-usb2 kmod-usb-ohci
    hasImageMetadata: 1
    SupportedDevices: nexx,wt3020-8m wt3020 wt3020-8M
...
```

Creamos los ficheros que queremos que se añadan a la imagen.  
Sirva de ejemplo este extracto donde:

* se crea un alias para obtener la ip pública
* se define `nano` como editor por defecto
* se añade la clave pública de la clave privada con la que queremos hacer `ssh` al router:

```console
$ mkdir files
$ cd openwrt*/
$ ln -s ../files
$ cd ..
$ mkdir -p files/etc/profile.d/
$ echo 'alias getip="wget -q ifconfig.me -O -"' > files/etc/profile.d/alias.sh
$ echo 'export EDITOR="nano"' > files/etc/profile.d/export.sh
$ mkdir -p files/etc/dropbear/
$ cp ~/.ssh/nexx.pub files/etc/dropbear/authorized_keys
```

Y usando [UCI defaults](https://openwrt.org/docs/guide-developer/uci-defaults)
afinamos la configuración.  
Sirva de ejemplo este extracto donde:

* se cambia la ip
* se elimina el `banner` que se muestra al logarse en el router

```console
$ mkdir -p files/etc/uci-defaults/
$ cat << EOF_cat > files/etc/uci-defaults/99_customizations.sh
#!/bin/sh
# Cambiar IP
sed 's/\b192\.168\.1\.1\b/192.168.8.1/g' -i /etc/config/network
# Borrar banner
rm /etc/banner
EOF_cat
```

Ver [`files` del repositorio](files/) para observar el resultado final.

## Creación de imagen

Ejemplo:

```console
$ mkdir bin
$ cd openwrt*/
$ make image PROFILE="wt3020-8M" PACKAGES="aircrack-ng airmon-ng kmod-usb-storage kmod-fs-ext4 kmod-usb-storage-extras block-mount kmod-scsi-core screen reaver nano uhttpd uhttpd-mod-ubus libiwinfo-lua luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap nodogsplash tcpdump luci-app-opkg luci-proto-ipv6 luci-proto-ppp luci rpcd-mod-rrdns luci shadow-chpasswd ipset" FILES=files/ BIN_DIR="$(realpath ..)/bin"
```

Para no tener que escribir esto cada vez, lo meto en el script [`build.sh`](build.sh) que
además se encarga de crear los ficheros de configuración para definir las claves para `root` y la red inalámbrica principal (en caso de que exista el fichero `env.sh`).

## Actualización

```
$ scp bin/openwrt-*-squashfs-sysupgrade.bin nexx:/tmp/
$ ssh nexx 'sysupgrade -n -v /tmp/openwrt-*-sysupgrade.bin'
```

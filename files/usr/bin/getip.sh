#!/bin/sh

getIp () {
   IP=$(wget -q -T 4 "$1" -O -)
   if [ ! -z "$IP" ] && [ ${#IP} -ge 8 ] && [ ${#IP} -le 16 ]; then
      echo "$IP"
      exit 0
   fi
}
getIp "http://ifconfig.me"
getIp "http://icanhazip.com"
exit 1

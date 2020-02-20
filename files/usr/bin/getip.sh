#!/bin/sh
DBG="$1"

MY_DIG=""

if command -v dig >/dev/null 2>&1; then
  MY_DIG="dig"
fi
if command -v kdig >/dev/null 2>&1; then
  MY_DIG="kdig"
fi

if [ ! -z "$MY_DIG" ]; then
  if [ "$DBG" == "-v" ]; then
    "$MY_DIG" +short myip.opendns.com @resolver1.opendns.com
  else
    "$MY_DIG" +short myip.opendns.com @resolver1.opendns.com 2>/dev/null
  fi
  exit $?
fi

getIp () {
   IP=$(wget -q -T 4 "http://$1" -O -)
   if [ ! -z "$IP" ] && [ ${#IP} -ge 8 ] && [ ${#IP} -le 16 ]; then
      echo "$IP"
      exit 0
   fi
   if [ "$DBG" == "-v" ]; then
      wget "http://$1" -O -
   fi
}
getIp ifconfig.me
getIp icanhazip.com
getIp ipecho.net/plain
getIp ifconfig.co
exit 1

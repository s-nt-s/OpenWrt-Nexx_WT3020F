#!/bin/sh
# Darle seguridad a la wifi
sed "s/option encryption 'none'/option encryption 'psk2'\n\toption key 'REPLACE_WITH_WIFI_PASS'/" -i /etc/config/wireless
sed "/option disabled '1'/d" -i /etc/config/wireless
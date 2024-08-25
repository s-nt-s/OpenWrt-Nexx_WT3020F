#!/bin/sh
# Guardar logs en un servidor syslog
uci set system.@system[0].log_ip='REPLACE_WITH_SRV_SYSLOG'
uci set system.@system[0].log_port='514'
uci commit system
#!/bin/sh

# add rule for wan gui

uci add firewall rule
uci set firewall.@rule[-1].name='Allow-Admin'
uci set firewall.@rule[-1].enabled='true'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='22 80 443'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
service firewall restart



# or add to /etc/config/firewall

# config rule
#         option name 'Allow-Admin'
#         option src 'wan'
#         option proto 'tcp'
#         option dest_port '22 80 443 8383'
#         option target 'ACCEPT'

#!/bin/sh

opkg update
opkg install sshtunnel

cat  >> /etc/config/sshtunnel <<EOF
config server '79rub'
	option hostname '91.149.218.39'
	option user 'root'
	option IdentityFile '/root/.ssh/id_ed25519'
	option LogLevel 'INFO'
	option Compression 'no'
	option retrydelay '10'
	option ServerAliveInterval '60'
	option CheckHostIP 'no'
	option StrictHostKeyChecking 'no'
	option port '22'

config tunnelW
	option server '79rub'
	option vpntype 'point-to-point'
	option localdev '77'
	option remotedev '77'
EOF
cat  >> /etc/config/network  <<EOF
config interface 'tun'
	option proto 'static'
	option device 'tun77'
	list ipaddr '192.168.222.2'

config route
	option interface 'tun'
	option target '192.168.222.1/32'
	option gateway '0.0.0.0'
EOF
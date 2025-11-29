##vm side
ip link set tun77 up
ip addr add 192.168.222.1/32 peer 192.168.222.2 dev tun77
ip route add 192.168.111.0/24 via 192.168.222.1
iptables -t nat -A POSTROUTING -s 192.168.222.2/32 -o eth0 -j MASQUERADE
iptables -A FORWARD -p tcp --syn -s 192.168.222.2/32 -j TCPMSS --set-mss 1356
iptables -t nat -A POSTROUTING -s 192.168.111.0/24 -o tun77 -j MASQUERADE

## router side
# install ssh tunnels package
# add ssh key and VPN Tunnel
# add tun77 device
# add tun interface - static route
# add static route

/etc/config/sshtunnel

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


/etc/config/network 

config interface 'tun'
	option proto 'static'
	option device 'tun77'
	list ipaddr '192.168.222.2'

config route
	option interface 'tun'
	option target '192.168.222.1/32'
	option gateway '0.0.0.0'
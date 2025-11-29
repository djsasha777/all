#!/bin/sh
opkg update
opkg install nebula


cat  >> /opt/nebula/config.yaml <<EOF
pki:
  ca: /opt/nebula/ca.crt
  cert: /opt/nebula/router.crt
  key: /opt/nebula/router.key

static_host_map:
  "192.168.49.1": ["91.149.218.39:4242"]

lighthouse:
  am_lighthouse: false
  interval: 60
  hosts:
    - "192.168.49.1"

listen:
  host: 0.0.0.0
  port: 4242

punchy:
  punch: true

relay:
  am_relay: false
  use_relays: true

tun:
  disabled: false
  dev: nebula1
  drop_local_broadcast: false
  drop_multicast: false
  tx_queue: 500
  mtu: 1300
  routes:
  unsafe_routes:

logging:

  level: info
  format: text

firewall:

  conntrack:
    tcp_timeout: 12m
    udp_timeout: 3m
    default_timeout: 10m

  outbound:
    - port: any
      proto: any
      host: any

  inbound:
    - port: any
      proto: any
      host: any
EOF

cat  >> /etc/config/firewall <<EOF
config zone
	option name 'nebula'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'
	list device 'nebula1'
	option masq '1'
	list network 'nebula1'
EOF

cat  >> /etc/config/network <<EOF
config interface 'nebula1'
	option proto 'nebula'
	option config_file '/opt/nebula/config.yaml'
EOF
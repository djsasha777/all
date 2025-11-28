#!/bin/bash
cat  >> /etc/systemd/system/tun2socks <<EOF
[Unit]
Description=Tun2Socks
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/tun2socks/tun2socks.conf
ExecStartPre=-ip tuntap add mode tun dev tun0
ExecStartPre=ip addr add ${TUNIP}/${TUNPREFIX} dev tun0
ExecStartPre=ip link set dev tun0 up
ExecStart=tun2socks -device tun://tun0 -proxy ss://${SSPROTOCOL}:${SSPASSWORD}@${SSIP}:${SSPORT}
ExecStartPost=ip r add default dev tun0 metric 50
ExecStopPost=-ip r flush table lip
ExecStopPost=-ip rule delete table lip
ExecStopPost=-ip link set dev tun0 down
ExecStopPost=-ip link del dev tun0

[Install]
WantedBy=multi-user.target
EOF

mkdir /etc/tun2socks
cat  >> /etc/tun2socks/tun2socks.conf <<EOF
TUNIP=10.10.0.1
TUNPREFIX=24
SSPROTOCOL=chacha20-ietf-poly1305
SSIP=195.0.0.1
SSPORT=8443
SSPASSWORD=YourPassword
EOF

systemctl enable --now tun2socks

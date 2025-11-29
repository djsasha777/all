#!/bin/bash
sudo rm /etc/sysconfig/network-scripts/ifcfg-eth0
touch /etc/sysconfig/network-scripts/ifcfg-eth0
cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
BOOTPROTO=static
DEVICE=eth0
HWADDR=0c:a9:5d:14:00:00
ONBOOT=yes
TYPE=Ethernet
IPADDR="10.10.20.49"
NETMASK="255.255.255.0"
GATEWAY="10.10.20.254"
EOF
sudo systemctl restart network
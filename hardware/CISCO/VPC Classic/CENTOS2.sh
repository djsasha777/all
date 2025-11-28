#!/bin/bash
sudo rm /etc/sysconfig/network-scripts/ifcfg-eth0
touch /etc/sysconfig/network-scripts/ifcfg-eth0
cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
BOOTPROTO=static
DEVICE=eth0
ONBOOT=yes
TYPE=Ethernet
IPADDR="10.10.40.50"
NETMASK="255.255.255.0"
GATEWAY="10.10.40.254"
EOF
sudo systemctl restart network
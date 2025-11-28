#!/bin/bash
# this script configure network on ubuntu host
rm /etc/netplan/*
touch 00-net-config.yaml
cat >> /etc/netplan/00-net-config.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: no
      addresses: [192.168.1.216/24]
      gateway4:  192.168.1.1
      nameservers:
              addresses: [192.168.1.1, 8.8.8.8]

EOF

sudo netplan apply




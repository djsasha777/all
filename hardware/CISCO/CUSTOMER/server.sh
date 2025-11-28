#!/bin/bash
cat >> /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      dhcp4: no
      addresses: [90.0.0.1/24, ]
      gateway4:  90.0.0.2
      nameservers:
              addresses: [8.8.8.8, 8.8.4.4]
    ens4:
      dhcp4: no
      dhcp6: no
      addresses: [91.0.0.1/24, ]
      nameservers:
              addresses: [8.8.8.8, 8.8.4.4]
EOF

sudo netplan apply
sudo apt update
sudo apt install -y curl python3 python3-pip
sudo python3 -m pip install --user ansible

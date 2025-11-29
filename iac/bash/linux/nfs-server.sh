#!/bin/bash
VERS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
if [[ "$VERS" == 'ubuntu' ]]; then
echo "your distributive is ${VERS}"
sudo apt update
sudo apt instll -y nfs-kernel-server
elif [[ "$VERS" == 'centos' ]]; then
echo "your distributive is ${VERS}"
yum install nfs-utils nfs-utils-lib
else
  echo "DISTRIBUTIVE NOT SUPPORT!"
fi
echo "Nfs server software is installed! now configuring!"
sudo mkdir -p /srv/nfs
sudo chown nobody:nogroup /srv/nfs
sudo chmod 0777 /srv/nfs
sudo mv /etc/exports /etc/exports.bak
echo '/media/AiDisk_a1/nfs 192.168.1.1/24(rw,sync,no_subtree_check)' | sudo tee /etc/exports
sudo systemctl restart nfs-kernel-server
echo "Nfs server is running"
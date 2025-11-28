#!/bin/bash
VERS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
if [[ "$VERS" == 'ubuntu' ]]; then
echo "your distributive is ${VERS}"
sudo apt update
sudo apt instll -y curl gpg
elif [[ "$VERS" == 'centos' ]]; then
echo "your distributive is ${VERS}"
yum install curl gpg
else
  echo "DISTRIBUTIVE NOT SUPPORT!"
fi
echo "This script will install and connect zerotier to your system"
echo "please enter zerotier netwirk id"
NETID=$(read)
curl -s https://install.zerotier.com | sudo bash
zerotier-cli join ${NETID}
echo "zerotier installed!"
echo "Please, allow your host in your zerotiers settings"
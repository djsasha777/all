#!/bin/bash
#this script install virtualhere usb over ethernet server

apt update
apt install curl -y
curl https://raw.githubusercontent.com/virtualhere/script/main/install_server | sh

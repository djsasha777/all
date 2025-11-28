#!/bin/bash
VERS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
if [[ "$VERS" == 'ubuntu' ]]; then
echo "your distributive is ${VERS}"
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.3.3-amd64.deb
sudo dpkg -i filebeat-8.3.3-amd64.deb
elif [[ "$VERS" == 'centos' ]]; then
echo "your distributive is ${VERS}"
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.3.3-x86_64.rpm
sudo rpm -vi filebeat-8.3.3-x86_64.rpm
else
  echo "DISTRIBUTIVE NOT SUPPORT!"
fi
echo "Filebeat are installed!"
#cp filebeat.yml /etc/filebeat/filebeat.yml
#systemctl restart filebeat
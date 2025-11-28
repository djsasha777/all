#!/bin/bash
echo "This script will install loki on your system!"
VERS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
if [[ "$VERS" == 'ubuntu' ]]; then
echo "your distributive is ${VERS}"
wget https://github.com/grafana/loki/releases/download/v2.7.3/loki_2.7.3_amd64.deb
wget https://github.com/grafana/loki/releases/download/v2.7.3/promtail_2.7.3_amd64.deb
dpkg -i loki_2.7.3_amd64.deb
dpkg -i promtail_2.7.3_amd64.deb
rm loki_2.7.3_amd64.deb
rm promtail_2.7.3_amd64.deb
elif [[ "$VERS" == 'centos' ]]; then
echo "your distributive is ${VERS}"
wget https://github.com/grafana/loki/releases/download/v2.7.3/loki-2.7.3.x86_64.rpm
wget https://github.com/grafana/loki/releases/download/v2.7.3/promtail-2.7.3.x86_64.rpm
rpm -i loki-2.7.3.x86_64.rpm
rpm -i promtail-2.7.3.x86_64.rpm
rm loki-2.7.3.x86_64.rpm
rm promtail-2.7.3.x86_64.rpm
else
  echo "DISTRIBUTIVE NOT SUPPORT!"
fi
echo "Loki and promtail are installed!"

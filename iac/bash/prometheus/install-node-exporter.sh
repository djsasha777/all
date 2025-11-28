#!/bin/bash
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" node_exporter
ARCHT=$(uname -m)
if [[ "$ARCHT" == 'aarch64' ]]; then
ARC=arm64
elif [[ "$ARCHT" == 'x86_64' ]]; then
ARC=amd64
elif [[ "$ARCHT" == 'arm64' ]]; then
ARC=arm64
elif [[ "$ARCHT" == 'amd64' ]]; then
ARC=amd64
else
  echo "ARCHITECTURE NOT SUPPORT!"
fi
echo "your architecture is ${ARC}"
VERSION=$(curl https://raw.githubusercontent.com/prometheus/node_exporter/master/VERSION)
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARC}.tar.gz
tar xvzf node_exporter-${VERSION}.linux-${ARC}.tar.gz
sudo cp node_exporter-${VERSION}.linux-${ARC}/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
cat node_exporter.service | sudo tee /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
rm node_exporter-${VERSION}.linux-${ARC}.tar.gz
rm -rf node_exporter-${VERSION}.linux-${ARC}
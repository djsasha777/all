#!/bin/bash
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
#install prometheus
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Prometheus Monitoring User" prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo touch /etc/prometheus/prometheus.yml
sudo touch /etc/prometheus/prometheus.rules.yml
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
VERSION=$(curl https://raw.githubusercontent.com/prometheus/prometheus/master/VERSION)
wget https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-${ARC}.tar.gz
tar xvzf prometheus-${VERSION}.linux-${ARC}.tar.gz
sudo cp prometheus-${VERSION}.linux-${ARC}/prometheus /usr/local/bin/
sudo cp prometheus-${VERSION}.linux-${ARC}/promtool /usr/local/bin/
sudo cp -r prometheus-${VERSION}.linux-${ARC}/consoles /etc/prometheus
sudo cp -r prometheus-${VERSION}.linux-${ARC}/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
cat prometheus.yml | sudo tee /etc/prometheus/prometheus.yml
cat prometheus.rules.yml | sudo tee /etc/prometheus/prometheus.rules.yml
cat prometheus.service | sudo tee /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
rm prometheus-${VERSION}.linux-${ARC}.tar.gz
rm -rf prometheus-${VERSION}.linux-${ARC}
#install node exporter
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" node_exporter
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
#install alert manager
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager
sudo mkdir /etc/alertmanager
sudo mkdir /etc/alertmanager/template
sudo mkdir -p /var/lib/alertmanager/data
sudo touch /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
VERSION=$(curl https://raw.githubusercontent.com/prometheus/alertmanager/master/VERSION)
wget https://github.com/prometheus/alertmanager/releases/download/v${VERSION}/alertmanager-${VERSION}.linux-${ARC}.tar.gz
tar xvzf alertmanager-${VERSION}.linux-${ARC}.tar.gz
sudo cp alertmanager-${VERSION}.linux-${ARC}/alertmanager /usr/local/bin/
sudo cp alertmanager-${VERSION}.linux-${ARC}/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool
cat alertmanager.yml | sudo tee /etc/alertmanager/alertmanager.yml
cat alertmanager.service | sudo tee /etc/systemd/system/alertmanager.service
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
rm alertmanager-${VERSION}.linux-${ARC}.tar.gz
rm -rf alertmanager-${VERSION}.linux-${ARC}
#instal blackbox
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Blackbox Exporter User" blackbox_exporter
sudo mkdir /etc/blackbox
sudo touch /etc/blackbox/blackbox.yml
sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox
VERSION=$(curl https://raw.githubusercontent.com/prometheus/blackbox_exporter/master/VERSION)
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${VERSION}/blackbox_exporter-${VERSION}.linux-${ARC}.tar.gz
tar xvzf blackbox_exporter-${VERSION}.linux-${ARC}.tar.gz
sudo cp blackbox_exporter-${VERSION}.linux-${ARC}/blackbox_exporter /usr/local/bin/
sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter
cat blackbox.yml | sudo tee /etc/blackbox/blackbox.yml
cat blackbox_exporter.service | sudo tee /etc/systemd/system/blackbox_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable blackbox_exporter
sudo systemctl start blackbox_exporter
rm blackbox_exporter-${VERSION}.linux-${ARC}.tar.gz
rm -rf blackbox_exporter-${VERSION}.linux-${ARC}
#install grafana
VERS=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
if [[ "$VERS" == 'ubuntu' ]]; then
echo "your distributive is ${VERS}"
apt update
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
sudo wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/enterprise/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana-enterprise
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server.service
elif [[ "$VERS" == 'centos' ]]; then
echo "your distributive is ${VERS}"
touch /etc/yum.repos.d/grafana.repo
cat >> /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/enterprise/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
sudo yum install grafana-enterprise
else
  echo "DISTRIBUTIVE NOT SUPPORT!"
fi
echo "All Prometheus stack is installed!"
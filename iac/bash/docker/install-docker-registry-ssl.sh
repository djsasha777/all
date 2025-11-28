#!/usr/bin/env bash

set -euo pipefail

sudo su
cd /root
# install docker https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
apt update
apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt install docker-ce -y
systemctl start docker

# install docker-compose https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04
curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# install letsencrypt https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04
add-apt-repository ppa:certbot/certbot -y
apt update
apt install certbot -y

# Generate SSL certificate for domain
certbot certonly --standalone --preferred-challenges http --non-interactive  --staple-ocsp --agree-tos -m admin@example.com -d example.com

# Setup letsencrypt certificates renewing 
cat <<EOF > /etc/cron.d/letencrypt
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
30 2 * * 1 root /usr/bin/certbot renew >> /var/log/letsencrypt-renew.log && cd /etc/letsencrypt/live/example.com && cp privkey.pem domain.key && cat cert.pem chain.pem > domain.crt && chmod 777 domain.*
EOF

# Rename SSL certificates
# https://community.letsencrypt.org/t/how-to-get-crt-and-key-files-from-i-just-have-pem-files/7348
cd /etc/letsencrypt/live/example.com && \
cp privkey.pem domain.key && \
cat cert.pem chain.pem > domain.crt && \
chmod 777 domain.*

#create a testuser 
mkdir -p /mnt/docker-registry
docker run --entrypoint htpasswd registry:latest -Bbn testuser testpass > /mnt/docker-registry/passfile
  
# https://docs.docker.com/registry/deploying/
docker run -d -p 443:5000 --restart=always --name registry \
  -v /etc/letsencrypt/live/domain.example.com:/certs \
  -v /mnt/docker-registry:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_AUTH=htpasswd \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/var/lib/registry/passfile \
  registry:latest
  
# List images
curl https://testuser:testpass@domain.example.com/v2/_catalog



# docker-compose.yaml
# registry:
#   restart: always
#   image: registry:latest
#   ports:
#     - 443:5000
#   environment:
#     REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
#     REGISTRY_HTTP_TLS_KEY: /certs/domain.key
#     REGISTRY_AUTH: htpasswd
#     REGISTRY_AUTH_HTPASSWD_PATH: /var/lib/registry/passfile
#     REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
#   volumes:
#     - /etc/letsencrypt/live/domain.example.com:/certs 
#     - /mnt/docker-registry:/var/lib/registry
#!/bin/sh
git clone https://github.com/djsasha777/all.git
cp -rf all/iac/openwrt/xiaomi-r3g/nginx/* /etc/nginx/
mv /etc/nginx/nginx-allconf.sh /root/run.sh
rm -rf hardware
chmod +x /root/run.sh
chmod 644 -R /etc/nginx
chmod 755 /etc/nginx
chmod 755 /etc/nginx/player
service nginx restart
echo "files copied and nginx restarted."
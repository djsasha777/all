#!/bin/sh
git clone https://github.com/djsasha777/all.git
cp -rf all/iac/openwrt/bpi-r3m/nginx/* /etc/nginx/
cp -r all/iac/openwrt/bpi-r3m/front /etc/
mv all/iac/openwrt/bpi-r3m/scripts/nginx-allconf.sh /root/run.sh
rm -rf all
chmod +x /root/run.sh
chmod 644 -R /etc/nginx
chmod 755 /etc/nginx
chmod 755 /etc/nginx/player
service nginx restart
echo "files copied and nginx restarted."
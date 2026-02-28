#!/bin/sh
chmod +x -R /var/run/acme
chmod +x -R /var/run/acme/challenge
/usr/lib/acme/client/acme.sh --debug --renew --force home /etc/acme -d spongo.ru
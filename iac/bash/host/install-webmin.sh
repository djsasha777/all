#!/bin/bash
(echo "[Webmin]
name=Webmin Distribution Neutral
baseurl=http://download.webmin.com/download/yum
enabled=1" >/etc/yum.repos.d/webmin.repo;
rpm --import https://www.webmin.com/jcameron-key.asc
yum -y install openssl openssl-devel
yum -y install perl perl-Net-SSLeay perl-Crypt-SSLeay
yum -y install webmin)
firewall-cmd --zone=public --add-port=10000/tcp --permanent
firewall-cmd --reload
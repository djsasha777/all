#!/bin/bash
#this script fix error "Failed to download metadata for repo 'AppStream'..." on CentOS8

cd /etc/yum.repos.d/
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum update -y
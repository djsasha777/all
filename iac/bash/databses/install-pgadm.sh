#!/bin/bash

# Installing pgadmin4

if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
        apt update
        apt install -y httpd python3-mod_wsgi pgadmin4-httpd
        mkdir -p /var/log/pgadmin4/
        systemctl start httpd
        systemctl enable httpd
        rm -f /usr/lib/pgadmin4/config_local.py
        touch /usr/lib/pgadmin4/config_local.py
        cat >> /usr/lib/pgadmin4/config_local.py <<EOF
import os 
from config import * 
HELP_PATH = '/usr/share/doc/pgadmin4/html/' 
DATA_DIR = os.path.realpath(os.path.expanduser(u'/var/lib/pgadmin4')) 
LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log') 
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db') 
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions') 
STORAGE_DIR = os.path.join(DATA_DIR, 'storage') 
AZURE_CREDENTIAL_CACHE_DIR = os.path.join(DATA_DIR, 'azurecredentialcache') 
KERBEROS_CCACHE_DIR = os.path.join(DATA_DIR, 'krbccache') 
TEST_SQLITE_PATH = os.path.join(DATA_DIR, 'test_pgadmin4.db')
EOF
        python /usr/lib/pgadmin4/setup.py
        chown -R apache:apache /var/lib/pgadmin4 /var/log/pgadmin4
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/lib/pgadmin4(/.*)?"
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/log/pgadmin4(/.*)?"
        restorecon -R /var/lib/pgadmin4/
        restorecon -R /var/log/pgadmin4/
        systemctl restart httpd
elif [ "$(grep -Ei 'fedora|redhat|centos' /etc/*release)" ]
    then
        echo "It's a RedHat based system."
        dnf install httpd python3-mod_wsgi pgadmin4-httpd
        mkdir -p /var/log/pgadmin4/
        systemctl start httpd
        systemctl enable httpd
        rm -f /usr/lib/pgadmin4/config_local.py
        touch /usr/lib/pgadmin4/config_local.py
        cat >> /usr/lib/pgadmin4/config_local.py <<EOF
import os 
from config import * 
HELP_PATH = '/usr/share/doc/pgadmin4/html/' 
DATA_DIR = os.path.realpath(os.path.expanduser(u'/var/lib/pgadmin4')) 
LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log') 
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db') 
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions') 
STORAGE_DIR = os.path.join(DATA_DIR, 'storage') 
AZURE_CREDENTIAL_CACHE_DIR = os.path.join(DATA_DIR, 'azurecredentialcache') 
KERBEROS_CCACHE_DIR = os.path.join(DATA_DIR, 'krbccache') 
TEST_SQLITE_PATH = os.path.join(DATA_DIR, 'test_pgadmin4.db')
EOF
        python /usr/lib/pgadmin4/setup.py
        chown -R apache:apache /var/lib/pgadmin4 /var/log/pgadmin4
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/lib/pgadmin4(/.*)?"
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/log/pgadmin4(/.*)?"
        restorecon -R /var/lib/pgadmin4/
        restorecon -R /var/log/pgadmin4/
        systemctl restart httpd   
else
    echo "This script doesn't support pgadmin4 installation on this OS."
fi
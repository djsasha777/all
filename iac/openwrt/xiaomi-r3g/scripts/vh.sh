#!/bin/sh
wget https://www.virtualhere.com/sites/default/files/usbserver/vhusbdarm64
chmod +x vhusbdarm64

mkdir -p /usr/local/sbin
mv vhusbdarm64 /usr/local/sbin/virtualhere
mkdir -p /usr/local/etc/virtualhere

cat > /etc/init.d/virtualhere << 'EOF'
#!/bin/sh /etc/rc.common

START=95
STOP=10
USE_PROCD=1

PROG="/usr/local/sbin/virtualhere"
CONF="/usr/local/etc/virtualhere/config.ini"
SERVICE_NAME="virtualhere"

start_service() {
    procd_open_instance
    procd_set_param command $PROG -b -c $CONF
    procd_set_param respawn
    procd_set_param user root
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

service_triggers() {
    procd_add_reload_trigger "virtualhere"
}
EOF

chmod +x /etc/init.d/virtualhere
/etc/init.d/virtualhere enable
/etc/init.d/virtualhere start
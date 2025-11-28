#!/bin/bash

cp /tmp/tunnel.sh /host

/usr/bin/nsenter -m/proc/1/ns/mnt -- chmod u+x /tmp/install/tunnel.sh

/usr/bin/nsenter -m/proc/1/ns/mnt /tmp/install/tunnel.sh --start

sleep infinity
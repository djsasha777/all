#!/bin/sh
# direct attach hdd drive to vm in proxmox
sudo apt update
sudo apt install lshw 
sudo lshw 
# find hdd disk for your mount
sudo qm set 103 -scsi2 /dev/disk/by-id/ata-HGST_HTS721010A9E630_JR40106LGTTUMG



# for erasing proxmox drive
lvremove /dev/pve/data  

# convert disc to qcow2
qemu-img convert -O qcow2 /dev/SSD-860/vm-109-disk-0 /mnt/openwrt.qcow2

# impord disc
qm importdisk 700 /mnt/openwrt.qcow2 SSD860 -format raw


#add phisical disc to vm
qm set 700 -scsi1 /dev/disk/by-id/ata-HP_SSD_S750_1TB_HASA43140200190

#add ntfs drive to proxmox ct
#connect drive
mkdir /media/ntfs
apt update
apt install ntfs-3g
#add to /etc/fstab
nano /etc/fstab
#add this->            /dev/sda1   /media/ntfs ntfs-3g    permissions,locale=en_US.utf8    0   2
systemctl daemon-reload
mount -a
#turn on CT and create dir on it ->     mkdir /ntfs
#stop ct
nano /etc/pve/lxc/200.conf
#add this ->          mp1: /media/ntfs,mp=/ntfs
#start ct

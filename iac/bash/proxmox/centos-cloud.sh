#!/bin/bash
sudo apt-get install -y libguestfs-tools
sudo wget https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20220627.1.x86_64.qcow2
sudo mv CentOS-Stream-GenericCloud-9-20220627.1.x86_64.qcow2 centos.qcow2
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/disable_root: [Tt]rue/disable_root: False/'
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/disable_root: 1/disable_root: 0/' 
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/lock_passwd: [Tt]rue/lock_passwd: False/'
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/lock_passwd: 1/lock_passwd: 0/'
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/- update_etc_hosts/#- update_etc_hosts/' 
sudo virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/ssh_pwauth:   0/ssh_pwauth:   1/';
sudo virt-customize -a centos.qcow2 --install cloud-init,htop,nano,qemu-guest-agent,curl,wget
sudo virt-edit -a centos.qcow2 /etc/ssh/sshd_config -e 's/PasswordAuthentication no/PasswordAuthentication yes/';
sudo virt-edit -a centos.qcow2 /etc/ssh/sshd_config -e 's/PermitRootLogin [Nn]o/PermitRootLogin yes/';
sudo virt-edit -a centos.qcow2 /etc/ssh/sshd_config -e 's/#PermitRootLogin [Yy]es/PermitRootLogin yes/';
sudo virt-edit -a centos.qcow2 /etc/ssh/sshd_config -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'
sudo qm create 9009 --name "centos" --memory 2048 --net0 virtio,bridge=vmbr0
sudo qm importdisk 9009 CentOS-Stream-GenericCloud-9-20220627.1.x86_64.qcow2 drive
sudo qm set 9009 --scsihw virtio-scsi-pci --scsi0 drive:vm-9009-disk-0
sudo qm set 9009 --ide2 drive:cloudinit
sudo qm set 9009 --boot c --bootdisk scsi0
sudo qm set 9009 --serial0 socket --vga serial0
sudo qm template 9009
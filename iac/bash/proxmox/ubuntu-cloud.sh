#!/bin/bash
sudo apt update -y
sudo apt install libguestfs-tools -y
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
sudo virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
virt-edit -a centos.qcow2 /etc/cloud/cloud.cfg -e 's/- update_etc_hosts/#- update_etc_hosts/'
sudo qm create 9000 --name "ubuntu" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
sudo qm importdisk 9000 focal-server-cloudimg-amd64.img drive
sudo qm set 9000 --scsihw virtio-scsi-pci --scsi0 drive:vm-9000-disk-0
sudo qm set 9000 --boot c --bootdisk scsi0
sudo qm set 9000 --ide2 drive:cloudinit
sudo qm set 9000 --serial0 socket --vga serial0
sudo qm set 9000 --agent enabled=1
sudo qm template 9000
rm focal-server-cloudimg-amd64.img
echo "next up, clone VM, then expand the disk"
echo "you also still need to copy ssh keys to the newly cloned VM"
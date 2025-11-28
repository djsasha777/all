#!/bin/bash

#this script resize home folder

# resize disk in proxmox gui

# resize partition in cfdisk utility

cfdisk
pvresize /dev/sda2
lvresize /dev/cs/home /dev/sda2
reboot
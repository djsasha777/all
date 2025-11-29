# create vlan with description
set vlans MYVLANS vlan-id 254 description "Access to switch"

# set interface em3 to switching
set interfaces xe-0/0/0 unit 0 family ethernet-switching

#set interface to trunk mode
set interfaces xe-0/0/0 unit 0 family ethernet-switching port-mode trunk

# set tranking vlans
set interfaces xe-0/0/0 unit 0 vlan members 254

#set interface to access mode
set interfaces xe-0/0/0 unit 0 family ethernet-switching port-mode access

#create sub interface
edit interface xe-0/0/0
set vlan-tagging
set unit 1 vlan-id 1 family inet address 192.168.1.1/24
set unit 2 vlan-id 2 family inet address 192.168.2.1/24
#configure LACP

#Access switch number one

enable
conf t
vlan 2
name PCVLAN2
exit
vlan 4
name PCVLAN4
exit
vlan 77
name TRUNK
exit
vlan 799
name DUMMY
exit
int e1/0
switchport mode access
switchport access vlan 2
description TOPC1
no sh
exit
int e1/1
switchport mode access
switchport access vlan 4
description TOPC2
no sh
exit
int e0/0
switchport access vlan 799
switchport trunk encapsulation dot1q
switchport mode trunk
switchport trunk native vlan 77
channel-group 1 mode active
no sh
exit
int e0/1
switchport access vlan 799
switchport trunk encapsulation dot1q
switchport mode trunk
switchport trunk native vlan 77
channel-group 1 mode active
no sh
exit
int po 1
switchport trunk native vlan 77
switchport trunk allowed vlan 2,4
no sh
exit
exit
wr
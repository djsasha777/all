#L2 configure

enable
conf t
vlan 10
name myvlan10
exit
vlan 20
name myvlan20
exit
vlan 999
name mytrunk999
exit
interface e0/1
switchport mode access
switchport access vlan 10
description PC1
exit
interface e0/2
switchport mode access
switchport access vlan 20
description PC2
exit
interface e0/0
switchport trunk encapsulation dot1q
switchport mode trunk
switchport trunk allowed vlan 10,20
switchport trunk native vlan 999
description TRUNKING
exit
exit
wr



#L3 router configure

enable
conf t
int e0/0
description TRtoSW
exit
int e0/0.1
encapsulation dot1Q 10
ip address 192.168.10.1 255.255.255.0
exit
int e0/0.2
encapsulation dot1Q 20
ip address 192.168.20.1 255.255.255.0
exit
int e0/0.999
encapsulation dot1Q 999 native
shutdown
exit
exit
wr
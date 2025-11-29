enable

conf t

hostname TOR1

vlan 20

exit

interface Port-channel20
 description to-spine
 switchport trunk encapsulation dot1q
 switchport mode trunk

interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 20 mode active

interface Ethernet0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 20 mode active

interface Ethernet0/2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 20 mode active

interface Ethernet0/3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 20 mode active

interface Ethernet2/0
 switchport access vlan 20
 switchport mode access

interface Ethernet2/1
 switchport access vlan 20
 switchport mode access

interface Ethernet2/2
 switchport access vlan 20
 switchport mode access

interface Ethernet2/3
 switchport access vlan 20
 switchport mode access

interface Vlan20
 ip address 10.10.20.201 255.255.255.0
 no shutdown

exit

ip default-gateway 10.10.20.254

end

wr
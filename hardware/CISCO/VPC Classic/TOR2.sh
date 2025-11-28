enable

conf t

hostname TOR2

vlan 40

exit

interface Port-channel40
 description to-spine
 switchport trunk encapsulation dot1q
 switchport mode trunk

interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 40 mode active

interface Ethernet0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 40 mode active

interface Ethernet0/2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 40 mode active

interface Ethernet0/3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 channel-group 40 mode active

interface Ethernet2/0
 switchport access vlan 40
 switchport mode access

interface Ethernet2/1
 switchport access vlan 40
 switchport mode access

interface Ethernet2/2
 switchport access vlan 40
 switchport mode access

interface Ethernet2/3
 switchport access vlan 40
 switchport mode access

interface Vlan40
 ip address 10.10.40.202 255.255.255.0
 no shutdown

exit

ip default-gateway 10.10.40.254

end

wr
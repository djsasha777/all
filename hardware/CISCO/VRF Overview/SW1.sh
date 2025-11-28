enable

conf t

hostname SW1

vlan 10,20,30

exit

interface FastEthernet0/1
 switchport access vlan 10

interface FastEthernet0/2
 switchport access vlan 20

interface FastEthernet0/3
 switchport access vlan 30

interface FastEthernet0/15
 switchport trunk encapsulation dot1Q
 switchport mode trunk

end

wr
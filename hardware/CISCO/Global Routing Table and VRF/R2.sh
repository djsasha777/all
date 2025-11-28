enable

conf t

hostname R2

vrf definition V1
 
 address-family ipv4
 exit-address-family

interface FastEthernet0/0
 ip address 192.168.12.2 255.255.255.0
 no shutdown

interface FastEthernet0/1
 vrf forwarding V1
 ip address 192.168.23.2 255.255.255.0
 ip policy route-map VRF_TO_GLOBAL
 no shutdown

ip route 192.168.23.0 255.255.255.0 FastEthernet0/1

access-list 100 permit ip 192.168.23.0 0.0.0.255 192.168.12.0 0.0.0.255

route-map VRF_TO_GLOBAL permit 10
 match ip address 100
 set global

end

wr
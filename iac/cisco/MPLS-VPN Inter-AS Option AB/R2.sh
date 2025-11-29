en 

conf t 

hostname R2

mpls label range 2000 2999

interface Loopback0
 ip address 2.2.2.2 255.255.255.255

interface FastEthernet0/0
 ip address 10.12.0.2 255.255.255.0
 mpls ip
 no shutdown

interface FastEthernet0/1
 ip address 10.23.0.2 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 passive-interface Loopback0
 network 2.2.2.2 0.0.0.0 area 0
 network 10.12.0.0 0.0.0.255 area 0
 network 10.23.0.0 0.0.0.255 area 0

end

wr
enable

conf t

hostname R3

mpls label range 3000 3999

interface Loopback0
 ip address 3.3.3.3 255.255.255.255

interface Ethernet1/0
 ip address 20.20.0.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip address 20.20.20.1 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/2
 ip address 30.30.30.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

end

wr
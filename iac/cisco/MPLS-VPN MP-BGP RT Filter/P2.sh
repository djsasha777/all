enable

conf t

hostname P2

mpls label range 2000 2999

interface Loopback0
 ip address 10.0.0.2 255.255.255.255

interface Ethernet1/0
 ip address 10.10.0.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip address 10.10.2.1 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/2
 ip address 10.10.3.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

end

wr

enable

conf t

hostname R1

mpls label range 1000 1999

interface Loopback0
 ip address 1.1.1.1 255.255.255.255

interface Ethernet1/0
 ip address 10.10.0.1 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip address 10.10.10.1 255.255.255.0
 mpls ip
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

end

wr
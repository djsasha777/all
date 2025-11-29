enable

conf t

hostname P1

interface Loopback0
 ip address 10.0.0.1 255.255.255.255

interface Ethernet1/0
 ip address 10.10.0.1 255.255.255.0
 mpls ip
  no shutdown

interface Ethernet1/1
 ip address 10.10.11.1 255.255.255.0
 mpls ip
  no shutdown

interface Ethernet1/2
 ip address 10.10.12.1 255.255.255.0
 mpls ip
  no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

ip forward-protocol nd
no ip http server
no ip http secure-server

end

wr


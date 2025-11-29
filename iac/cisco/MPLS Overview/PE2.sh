enable

conf t

hostname R5

mpls label range 5000 5999

interface Loopback0
 ip address 5.5.5.5 255.255.255.255

interface Ethernet1/0
 ip address 20.20.20.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip address 192.168.20.1 255.255.255.0
 no shutdown

router ospf 1
 network 5.5.5.5 0.0.0.0 area 0
 network 20.0.0.0 0.255.255.255 area 0

router bgp 65000
 bgp log-neighbor-changes
 neighbor 4.4.4.4 remote-as 65000
 neighbor 4.4.4.4 update-source Loopback0
 neighbor 4.4.4.4 next-hop-self
 neighbor 4.4.4.4 send-label
 neighbor 192.168.20.2 remote-as 65008

end

wr
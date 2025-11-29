enable

conf t

hostname R4

mpls label range 4000 4999

interface Loopback0
 ip address 4.4.4.4 255.255.255.255

interface Ethernet1/0
 ip address 10.10.10.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip address 192.168.10.1 255.255.255.0
 no shutdown

router ospf 1
 network 4.4.4.4 0.0.0.0 area 0
 network 10.0.0.0 0.255.255.255 area 0

router bgp 65000
 bgp log-neighbor-changes
 neighbor 5.5.5.5 remote-as 65000
 neighbor 5.5.5.5 update-source Loopback0
 neighbor 5.5.5.5 next-hop-self
 neighbor 5.5.5.5 send-label
 neighbor 6.6.6.6 remote-as 65000
 neighbor 6.6.6.6 update-source Loopback0
 neighbor 6.6.6.6 next-hop-self
 neighbor 6.6.6.6 send-label
 neighbor 192.168.10.2 remote-as 65007

end

wr
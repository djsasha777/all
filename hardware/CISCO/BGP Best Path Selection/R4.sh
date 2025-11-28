enable

conf t

hostname R4

interface Loopback0
 ip address 10.0.0.4 255.255.255.255

interface Ethernet1/0
 ip address 192.168.4.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.5.2 255.255.255.0
 no shutdown

interface Ethernet1/2
 ip address 192.168.6.1 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.6.0 0.0.0.255 area 0

router bgp 65001
 bgp router-id 10.0.0.4
 bgp log-neighbor-changes
 neighbor 10.0.0.5 remote-as 65001
 neighbor 10.0.0.5 update-source Loopback0
 neighbor 10.0.0.5 next-hop-self
 neighbor 192.168.4.1 remote-as 65000
 neighbor 192.168.5.1 remote-as 65000

end

wr

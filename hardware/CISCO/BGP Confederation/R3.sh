en 

conf t 

hostname R3

interface Loopback0
 ip address 10.0.0.3 255.255.255.255

interface Ethernet1/0
 ip address 192.168.3.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.5.1 255.255.255.0
 no shutdown

interface Ethernet1/2
 ip address 192.168.37.3 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.37.0 0.0.0.255 area 0

router bgp 65531
 bgp log-neighbor-changes
 bgp confederation identifier 65000
 bgp confederation peers 65530 
 neighbor 10.0.0.7 remote-as 65531
 neighbor 10.0.0.7 update-source Loopback0
 neighbor 10.0.0.7 next-hop-self
 neighbor 192.168.3.1 remote-as 65530
 neighbor 192.168.3.1 next-hop-self
 neighbor 192.168.5.2 remote-as 65530
 neighbor 192.168.5.2 next-hop-self

end

wr
en 

conf t 

hostname R1

interface Loopback0
 ip address 10.0.0.1 255.255.255.255

interface Ethernet1/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.2.1 255.255.255.0
 no shutdown

interface Ethernet1/2
 ip address 192.168.3.1 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.2.0 0.0.0.255 area 0

router bgp 65530
 bgp log-neighbor-changes
 bgp confederation identifier 65000
 bgp confederation peers 65531 
 network 192.168.1.0
 neighbor 10.0.0.2 remote-as 65530
 neighbor 10.0.0.2 update-source Loopback0
 neighbor 10.0.0.2 next-hop-self
 neighbor 10.0.0.4 remote-as 65530
 neighbor 10.0.0.4 update-source Loopback0
 neighbor 10.0.0.4 next-hop-self
 neighbor 192.168.3.2 remote-as 65531
 neighbor 192.168.3.2 next-hop-self

end

wr
en 

conf t 

hostname R7

interface Loopback0
 ip address 10.0.0.7 255.255.255.255

interface Ethernet1/0
 ip address 192.168.37.7 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.17.7 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.37.0 0.0.0.255 area 0

router bgp 65531
 bgp log-neighbor-changes
 bgp confederation identifier 65000
 network 192.168.17.0
 neighbor 10.0.0.3 remote-as 65531
 neighbor 10.0.0.3 update-source Loopback0

end

wr
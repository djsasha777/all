en 

conf t 

hostname R5

interface Loopback0
 ip address 10.0.0.5 255.255.255.255

interface Ethernet1/0
 ip address 192.168.6.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.7.1 255.255.255.0
 no shutdown

router bgp 65001
 bgp router-id 5.5.5.5
 bgp log-neighbor-changes
 neighbor 192.168.6.1 remote-as 65000
 neighbor 192.168.7.2 remote-as 65002

end

wr
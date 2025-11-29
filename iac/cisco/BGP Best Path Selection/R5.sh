enable

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

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.6.0 0.0.0.255 area 0
 network 192.168.7.0 0.0.0.255 area 0

router bgp 65001
 bgp router-id 10.0.0.5
 bgp log-neighbor-changes
 network 192.168.7.0
 neighbor 10.0.0.4 remote-as 65001
 neighbor 10.0.0.4 update-source Loopback0

end

wr

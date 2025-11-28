enable

conf t

hostname R1

interface Loopback0
 ip address 10.0.0.1 255.255.255.0

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
 network 192.168.1.0 0.0.0.255 area 0
 network 192.168.2.0 0.0.0.255 area 0
 network 192.168.3.0 0.0.0.255 area 0

router bgp 65000
 bgp router-id 10.0.0.1
 bgp log-neighbor-changes
 network 192.168.1.0
 neighbor 10.0.0.2 remote-as 65000
 neighbor 10.0.0.2 update-source Loopback0
 neighbor 10.0.0.3 remote-as 65000
 neighbor 10.0.0.3 update-source Loopback0
 neighbor 10.0.0.4 remote-as 65000
 neighbor 10.0.0.4 update-source Loopback0

end

wr
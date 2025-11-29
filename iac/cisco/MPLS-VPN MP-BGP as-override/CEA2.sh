enable

conf t

hostname CEA2

interface Loopback0
 ip address 10.0.0.7 255.255.255.255

interface Ethernet1/0
 ip address 192.168.11.2 255.255.255.0
  no shutdown

interface Ethernet1/1
 ip address 192.168.12.1 255.255.255.0
  no shutdown

router ospf 1
 network 192.168.11.0 0.0.0.255 area 2
 network 192.168.12.0 0.0.0.255 area 2

router bgp 65530
 bgp log-neighbor-changes
 network 192.168.11.0
 network 192.168.12.0
 neighbor 192.168.11.1 remote-as 65000

end

wr


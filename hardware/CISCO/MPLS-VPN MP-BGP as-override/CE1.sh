enable

conf t

hostname CE1

interface Loopback0
 ip address 10.0.0.6 255.255.255.255

interface Ethernet1/0
 ip address 192.168.0.2 255.255.255.0
  no shutdown

interface Ethernet1/1
 ip address 192.168.1.2 255.255.255.0
  no shutdown

interface Ethernet1/2
 ip address 192.168.2.1 255.255.255.0
  no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 0
 network 192.168.0.0 0.0.0.255 area 0
 network 192.168.1.0 0.0.0.255 area 0
 network 192.168.2.0 0.0.0.255 area 0

router bgp 65530
 bgp log-neighbor-changes
 network 192.168.0.0
 network 192.168.1.0
 network 192.168.2.0
 neighbor 10.0.0.13 remote-as 65530
 neighbor 10.0.0.13 update-source Loopback0
 neighbor 192.168.0.1 remote-as 65000
 neighbor 192.168.1.1 remote-as 65000
 maximum-paths 2

end

wr


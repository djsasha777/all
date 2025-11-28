enable

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

router bgp 65000
 bgp router-id 10.0.0.1
 bgp log-neighbor-changes
 network 192.168.1.0
 neighbor 192.168.2.2 remote-as 65001
 neighbor 192.168.3.2 remote-as 65001
 maximum-paths 2

end

wr

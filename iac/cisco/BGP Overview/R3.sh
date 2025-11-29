enable

conf t

hostname R3

interface Loopback0
 ip address 10.0.0.3 255.255.255.0

interface Ethernet1/0
 ip address 192.168.2.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.3.1 255.255.255.0
 no shutdown

router bgp 65001
 bgp router-id 10.0.0.3
 bgp log-neighbor-changes
 network 192.168.3.0
 neighbor 192.168.2.1 remote-as 65000

end

wr

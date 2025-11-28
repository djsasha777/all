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

interface Ethernet1/2
 ip address 192.168.8.1 255.255.255.0
 no shutdown

router bgp 65002
 bgp router-id 10.0.0.5
 bgp log-neighbor-changes
 network 192.168.7.0
 neighbor 192.168.6.1 remote-as 65001

end

wr

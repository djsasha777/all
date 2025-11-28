enable

conf t

hostname R8

interface Loopback0
 ip address 8.8.8.8 255.255.255.255

interface Ethernet1/0
 ip address 192.168.20.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.21.1 255.255.255.0
 no shutdown

router bgp 65008
 bgp log-neighbor-changes
 network 8.8.8.8 mask 255.255.255.255
 neighbor 192.168.20.1 remote-as 65000

end

wr
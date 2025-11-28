enable

conf t

hostname R9

interface Loopback0
 ip address 9.9.9.9 255.255.255.255

interface Ethernet1/0
 ip address 192.168.30.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.31.1 255.255.255.0
 no shutdown

router bgp 65009
 bgp log-neighbor-changes
 network 9.9.9.9 mask 255.255.255.255
 neighbor 192.168.30.1 remote-as 65000

end

wr
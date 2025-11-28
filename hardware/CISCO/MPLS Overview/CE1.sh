enable

conf t

hostname R7

interface Loopback0
 ip address 7.7.7.7 255.255.255.255

interface Ethernet1/0
 ip address 192.168.10.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.11.1 255.255.255.0
 no shutdown

router bgp 65007
 bgp log-neighbor-changes
 network 7.7.7.7 mask 255.255.255.255
 neighbor 192.168.10.1 remote-as 65000

end

wr


interface Ethernet0/0
 ip address 192.169.0.2 255.255.255.0
 no shutdown

 router bgp 65007
 network 192.169.0.0 mask 255.255.255.0

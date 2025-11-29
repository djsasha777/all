enable

conf t

hostname R2

ip multicast-routing

interface Loopback0
 ip address 2.2.2.2 255.255.255.255

interface FastEthernet0/0
 ip address 192.168.12.2 255.255.255.0
 ip pim sparse-mode
 no shutdown

interface FastEthernet0/1
 ip address 192.168.23.2 255.255.255.0
 ip pim sparse-mode
 no shutdown

interface FastEthernet1/0
 ip address 192.168.24.2 255.255.255.0
 ip pim sparse-mode
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

ip pim rp-address 2.2.2.2
ip pim spt-threshold infinity

end

wr
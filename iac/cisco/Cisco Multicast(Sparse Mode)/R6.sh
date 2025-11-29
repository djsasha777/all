enable

conf t

hostname R6

ip multicast-routing 

interface FastEthernet0/0
 ip address 192.168.56.6 255.255.255.0
 ip pim sparse-mode
 ip multicast-routing

interface FastEthernet0/1
 ip address 192.168.60.6 255.255.255.0
 ip pim sparse-mode
 ip multicast-routing

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

ip pim rp-address 2.2.2.2
ip pim spt-threshold infinity

end

wr
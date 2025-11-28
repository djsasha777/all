enable

conf t

hostname CEA2

interface Ethernet1/0
 ip address 192.168.11.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.12.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.11.0 0.0.0.255 area 2
 network 192.168.12.0 0.0.0.255 area 2

end

wr

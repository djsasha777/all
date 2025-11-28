enable

conf t

hostname CEA3

interface Ethernet1/0
 ip address 192.168.13.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.14.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.13.0 0.0.0.255 area 3
 network 192.168.14.0 0.0.0.255 area 3

end

wr

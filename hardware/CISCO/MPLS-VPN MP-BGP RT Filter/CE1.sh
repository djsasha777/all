enable

conf t

hostname CE1

interface Ethernet1/0
 ip address 192.168.0.2 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 192.168.1.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.0.0 0.0.0.255 area 1
 network 192.168.1.0 0.0.0.255 area 1

end

wr

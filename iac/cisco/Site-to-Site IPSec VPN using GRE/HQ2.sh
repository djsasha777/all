enable

conf t

hostname HQ2

interface FastEthernet0/0
 ip address 192.168.0.2 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 192.168.1.1 255.255.255.0
 no shutdown

router ospf 1
 network 192.168.0.0 0.0.255.255 area 0

end

wr
enable

conf t

hostname R1

interface FastEthernet1/0
 ip address 10.0.0.1 255.255.255.0
 no shutdown

interface FastEthernet1/1
 ip address 20.0.0.1 255.255.255.0
 no shutdown

interface FastEthernet1/2
 ip address 30.0.0.1 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0
 network 20.0.0.0 0.255.255.255 area 0
 network 30.0.0.0 0.255.255.255 area 0

end

wr

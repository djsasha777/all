en 

conf t

hostname R9

interface Loopback0
 ip address 9.9.9.9 255.255.255.255

interface FastEthernet0/0
 ip address 172.16.89.9 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 172.16.90.9 255.255.255.0
 no shutdown

router ospf 200
 passive-interface Loopback0
 network 9.9.9.9 0.0.0.0 area 0
 network 172.16.89.0 0.0.0.255 area 0
 network 172.16.90.0 0.0.0.255 area 0

end

wr
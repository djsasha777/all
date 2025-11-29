en 

conf t 

hostname R4

interface Loopback0
 ip address 4.4.4.4 255.255.255.255

interface FastEthernet0/0
 ip address 172.16.34.4 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 172.16.40.4 255.255.255.0
 no shutdown

router ospf 200
 passive-interface Loopback0
 network 4.4.4.4 0.0.0.0 area 0
 network 172.16.34.0 0.0.0.255 area 0
 network 172.16.40.0 0.0.0.255 area 0

end

wr
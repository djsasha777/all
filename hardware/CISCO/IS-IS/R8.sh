
hostname R8

interface FastEthernet0/0
 ip address 172.17.0.8 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 12.0.0.8 255.255.255.0
 no shutdown

router ospf 1
 network 12.0.0.0 0.0.0.255 area 0
 network 172.17.0.0 0.0.0.255 area 0

end
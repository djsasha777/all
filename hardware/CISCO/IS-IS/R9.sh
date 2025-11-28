
hostname R9

interface FastEthernet0/0
 ip address 172.17.0.9 255.255.255.0
 no shutdown

router ospf 1
 network 172.17.0.0 0.0.0.255 area 0

end
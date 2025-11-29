
hostname R10

interface FastEthernet0/0
 ip address 172.18.0.10 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 13.0.0.10 255.255.255.0
 no shutdown

router eigrp 10
 network 13.0.0.0 0.0.0.255
 network 172.18.0.0 0.0.0.255

end

hostname R11

interface FastEthernet0/0
 ip address 172.18.0.11 255.255.255.0
 no shutdown

router eigrp 10
 network 172.18.0.0 0.0.0.255

end
en 

conf t 

hostname R5

interface Loopback0
 ip address 5.5.5.5 255.255.255.255

interface FastEthernet0/0
 ip address 172.16.35.5 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 172.16.50.5 255.255.255.0
 no shutdown

router eigrp 1
 network 5.5.5.5 0.0.0.0
 network 172.16.35.0 0.0.0.255
 network 172.16.50.0 0.0.0.255
 passive-interface Loopback0

end

wr
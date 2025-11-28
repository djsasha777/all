en 

conf t 

hostname R10

interface Loopback0
 ip address 10.10.10.10 255.255.255.255

interface FastEthernet0/0
 ip address 172.16.108.10 255.255.255.0
 no shutdown

interface FastEthernet0/1
 ip address 172.16.110.10 255.255.255.0

router eigrp 1
 network 10.0.0.0
 network 172.16.108.0 0.0.0.255
 network 172.16.110.0 0.0.0.255

end

wr
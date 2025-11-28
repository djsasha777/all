
en 

conf t

hostname CustA3

interface FastEthernet0/0
 ip address 192.168.3.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.30.1 255.255.255.0
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

end

wr
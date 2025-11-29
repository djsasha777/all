
en 

conf t

hostname CustB4

interface FastEthernet0/0
 ip address 192.168.4.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.40.1 255.255.255.0
 no shutdown

router ospf 1
 network 0.0.0.0 255.255.255.255 area 0

end

wr
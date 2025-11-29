enable

conf t

hostname CustA2

interface FastEthernet0/0
 ip address 192.168.10.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.11.1 255.255.255.0
 no shutdown

router rip
 version 2
 network 192.168.10.0
 network 192.168.11.0

end

wr
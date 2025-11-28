enable

conf t

hostname CustC3

interface FastEthernet0/0
 ip address 192.168.100.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.101.1 255.255.255.0
 no shutdown

router rip
 version 2
 network 192.168.100.0
 network 192.168.101.0

end

wr
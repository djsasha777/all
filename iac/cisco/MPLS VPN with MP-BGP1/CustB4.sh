
enable

conf t

hostname CustB4

interface FastEthernet0/0
 ip address 192.168.120.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.121.1 255.255.255.0
 no shutdown

router rip
 version 2
 network 192.168.120.0
 network 192.168.121.0

end

wr
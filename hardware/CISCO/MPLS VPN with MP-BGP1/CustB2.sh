enable

conf t

hostname CustB2

interface FastEthernet0/0
 ip address 192.168.20.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.21.1 255.255.255.0
 no shutdown

router eigrp 220
 network 192.168.20.0
 network 192.168.21.0
 auto-summary

end

wr
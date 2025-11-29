enable

conf t

hostname CustA1

interface FastEthernet0/0
 ip address 192.168.0.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown

router eigrp 110
 network 192.168.0.0
 network 192.168.1.0
 auto-summary

end

wr
enable

conf t

hostname CustC4

interface FastEthernet0/0
 ip address 192.168.130.2 255.255.255.0
 no shutdown

interface FastEthernet1/0
 ip address 192.168.131.1 255.255.255.0
 no shutdown

router eigrp 320
 network 192.168.130.0
 network 192.168.131.0
 auto-summary

end

wr
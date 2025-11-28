
hostname R6

interface FastEthernet0/0
 ip address 11.0.0.6 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet0/1
 ip address 172.16.0.6 255.255.255.0
 ip router isis 
 no shutdown

router isis
 net 49.0003.0000.0000.0006.00

end
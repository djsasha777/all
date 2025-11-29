
hostname R2

interface FastEthernet0/0
 ip address 10.0.0.2 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet0/1
 ip address 192.168.0.2 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet1/0
 ip address 192.168.2.2 255.255.255.0
 ip router isis 
 no shutdown

router isis
 net 49.0002.0000.0000.0002.00

end
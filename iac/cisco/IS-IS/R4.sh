
hostname R4

interface FastEthernet0/0
 ip address 192.168.1.4 255.255.255.0
 ip router isis 
 no shutdown

interface FastEthernet0/1
 no ip address
 shutdown
 no shutdown

router isis
 net 49.0002.0000.0000.0004.00
 is-type level-1

end
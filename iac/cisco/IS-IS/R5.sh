
hostname R5

interface FastEthernet0/0
 ip address 192.168.2.5 255.255.255.0
 ip router isis 
 no shutdown

router isis
 net 49.0002.0000.0000.0005.00
 is-type level-1

end
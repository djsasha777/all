enable

conf t

hostname PPPoE_Server

username HUB1 password 0 HUB1PASS
username SPOKE1 password 0 SPOKE1PASS
username SPOKE2 password 0 SPOKE2PASS

bba-group pppoe GROUP1
 virtual-template 1

bba-group pppoe GROUP2
 virtual-template 2

bba-group pppoe GROUP3
 virtual-template 3

interface Loopback1
 ip address 100.0.0.1 255.255.255.255

interface Loopback2
 ip address 100.0.0.2 255.255.255.255

interface Loopback3
 ip address 100.0.0.3 255.255.255.255

interface Ethernet1/0
 no ip address
 duplex half
 pppoe enable group GROUP1

interface Ethernet1/1
 no ip address
 duplex half
 pppoe enable group GROUP2

interface Ethernet1/2
 no ip address
 duplex half
 pppoe enable group GROUP3

interface Ethernet1/3
 no ip address
 shutdown
 duplex half

interface Virtual-Template1
 mtu 1454
 ip unnumbered Loopback1
 peer default ip address pool POOL1
 no keepalive
 ppp authentication chap

interface Virtual-Template2
 mtu 1454
 ip unnumbered Loopback2
 peer default ip address pool POOL2
 no keepalive
 ppp authentication chap

interface Virtual-Template3
 mtu 1454
 ip unnumbered Loopback3
 peer default ip address pool POOL2
 no keepalive
 ppp authentication chap

ip local pool POOL1 100.1.1.1
ip local pool POOL2 200.1.1.1 200.1.1.254

end

wr
enable

conf t

hostname NAT

interface Ethernet1/0
 no ip address
 duplex half
 pppoe enable group global
 pppoe-client dial-pool-number 1

interface Ethernet1/1
 ip address 192.168.250.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in
 duplex half

interface Dialer1
 ip address negotiated
 ip mtu 1454
 ip nat outside
 ip virtual-reassembly in
 encapsulation ppp
 dialer pool 1
 dialer idle-timeout 0
 dialer-group 1
 ppp authentication chap callin
 ppp chap hostname SPOKE2
 ppp chap password 0 SPOKE2PASS
 ppp ipcp dns request accept

ip nat inside source list 1 interface Dialer1 overload
ip route 0.0.0.0 0.0.0.0 Dialer1

access-list 1 permit 192.168.250.0 0.0.0.255
dialer-list 1 protocol ip permit

end

wr
enable

conf t

username admin privilege 15 secret 0 cisco
service password-encryption
enable secret gorizont
aaa new-model
ip domain name local.domain
ip name-server 8.8.8.8
no ip domain-lookup
ip ssh ver 2
crypto key generate rsa general-keys modulus 1024
line console 0
password cisco
line vty 0 4
password cisco
aaa authentication login vty local
aaa authorization network default if-authenticated
line vty 0 4
transport input ssh

hostname CORE2

interface Loopback0
 ip address 10.0.0.6 255.255.255.255

interface Ethernet0/0
 ip address 172.0.0.2 255.255.255.0
 no shutdown

interface Ethernet0/1
 ip address 173.2.0.2 255.255.255.0
 no shutdown

interface Ethernet0/2
 ip address 173.4.0.2 255.255.255.0
 no shutdown

interface Ethernet1/0
 ip address 172.0.3.1 255.255.255.0
 no shutdown

interface Ethernet1/1
 ip address 172.0.5.1 255.255.255.0
 no shutdown

interface Ethernet3/0
 ip address 91.0.0.2 255.255.255.0
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 1
 network 91.0.0.0 0.0.0.255 area 1
 network 172.0.0.0 0.0.0.255 area 1
 network 172.0.3.0 0.0.0.255 area 1
 network 172.0.5.0 0.0.0.255 area 1
 network 173.2.0.0 0.0.0.255 area 1
 network 173.4.0.0 0.0.0.255 area 1
 default-information originate

end

wr
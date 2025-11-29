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

vlan 10,20,30,777,999

hostname DISTRIBUTION1

ip dhcp excluded-address 10.10.10.1
ip dhcp excluded-address 10.10.10.2
ip dhcp excluded-address 10.10.10.3

ip dhcp excluded-address 10.10.20.1
ip dhcp excluded-address 10.10.20.2
ip dhcp excluded-address 10.10.20.3

ip dhcp excluded-address 10.10.30.1
ip dhcp excluded-address 10.10.30.2
ip dhcp excluded-address 10.10.30.3

ip dhcp pool pool10
 network 10.10.10.0 255.255.255.0
 default-router 10.10.10.1 
 dns-server 8.8.8.8 

ip dhcp pool pool20
 network 10.10.20.0 255.255.255.0
 default-router 10.10.20.1 
 dns-server 8.8.8.8

ip dhcp pool pool30
 network 10.10.30.0 255.255.255.0
 default-router 10.10.30.1
 dns-server 8.8.8.8

spanning-tree mode pvst
spanning-tree extend system-id
spanning-tree vlan 10,20,30,777 priority 28672

interface Loopback0
 ip address 10.0.0.8 255.255.255.255

interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNK-BETWEEN-DISTRIBUTION
 no shutdown

interface Ethernet0/1
 no switchport
 ip address 172.0.1.2 255.255.255.0
 no shutdown

interface Ethernet0/2
 no switchport
 ip address 172.0.3.2 255.255.255.0
 no shutdown

interface Ethernet1/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet1/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet1/2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet1/3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Vlan10
 ip address 10.10.10.3 255.255.255.0
 standby 10 ip 10.10.10.1
 standby 10 priority 100
 standby 10 preempt
 no shutdown

interface Vlan20
 ip address 10.10.20.3 255.255.255.0
 standby 20 ip 10.10.20.1
 standby 20 priority 100
 standby 20 preempt
 no shutdown

interface Vlan30
 ip address 10.10.30.3 255.255.255.0
 standby 30 ip 10.10.30.1
 standby 30 priority 100
 standby 30 preempt
 no shutdown

interface Vlan777
 ip address 77.77.1.3 255.255.0.0
 standby 77 ip 77.77.1.1
 standby 77 priority 100
 standby 77 preempt
 no shutdown

router ospf 1
 network 10.0.0.0 0.0.0.255 area 1
 network 10.10.10.0 0.0.0.255 area 1
 network 10.10.20.0 0.0.0.255 area 1
 network 10.10.30.0 0.0.0.255 area 1
 network 77.77.0.0 0.0.255.255 area 1
 network 172.0.1.0 0.0.0.255 area 1
 network 172.0.3.0 0.0.0.255 area 1

 end

wr
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

hostname ACCESS1

spanning-tree mode pvst
spanning-tree extend system-id

interface Loopback0
 ip address 10.0.0.9 255.255.255.255

interface Vlan777
 ip address 77.77.0.1 255.255.0.0
 no shutdown

interface Ethernet0/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet0/1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet0/2
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet0/3
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,777
 switchport trunk native vlan 999
 description TRUNKING
 no shutdown

interface Ethernet1/0
 switchport access vlan 10
 switchport mode access
 description COMMON_INTERNET_USERS
 no shutdown

interface Ethernet1/1
 switchport access vlan 10
 switchport mode access
 description COMMON_INTERNET_USERS
 no shutdown

interface Ethernet1/2
 switchport access vlan 10
 switchport mode access
 description COMMON_INTERNET_USERS
 no shutdown

interface Ethernet1/3
 switchport access vlan 10
 switchport mode access
 description COMMON_INTERNET_USERS
 no shutdown

interface Ethernet2/0
 switchport access vlan 20
 switchport mode access
 description BUISNESS_USERS
 no shutdown

interface Ethernet2/1
 switchport access vlan 20
 switchport mode access
 description BUISNESS_USERS
 no shutdown

interface Ethernet2/2
 switchport access vlan 20
 switchport mode access
 description BUISNESS_USERS
 no shutdown

interface Ethernet2/3
 switchport access vlan 20
 switchport mode access
 description BUISNESS_USERS
 no shutdown
        
interface Ethernet3/0
 switchport access vlan 30
 switchport mode access
 description IPTV_USERS
 no shutdown

interface Ethernet3/1
 switchport access vlan 30
 switchport mode access
 description IPTV_USERS
 no shutdown

interface Ethernet3/2
 switchport access vlan 30
 switchport mode access
 description IPTV_USERS
 no shutdown

interface Ethernet3/3
 switchport access vlan 30
 switchport mode access
 description IPTV_USERS
 no shutdown

ip default-gateway 77.77.1.1

end

wr
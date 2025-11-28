conf t

hostname SPINE2

feature vrrp
cfs eth distribute
feature ospf
feature interface-vlan
feature lacp
feature vpc

vlan 1,20,40

vrf context keepalive

vpc domain 1
  peer-gateway
  peer-keepalive destination 192.169.0.1 source 192.169.0.2 vrf keepalive

interface Vlan20
  no shutdown
  ip address 10.10.20.252/24
  vrrp 20
    address 10.10.20.254 
    no shutdown

interface Vlan40
  no shutdown
  ip address 10.10.40.252/24
  vrrp 40
    address 10.10.40.254 
    no shutdown

interface port-channel1
  switchport mode trunk
  spanning-tree port type network
  vpc peer-link

interface port-channel20
  switchport mode trunk
  vpc 20

interface port-channel40
  switchport mode trunk
  vpc 40

interface Ethernet1/1
  no switchport
  ip address 172.0.1.2/24
  no shutdown

interface Ethernet1/2
  no switchport
  ip address 172.0.3.2/24
  no shutdown

interface Ethernet1/3
  description CLIENT*LINKS1
  switchport mode trunk
  channel-group 20 mode active

interface Ethernet1/4
  description CLIENT*LINKS1
  switchport mode trunk
  channel-group 20 mode active

interface Ethernet1/5
  description CLIENT*LINKS2
  switchport mode trunk
  channel-group 40 mode active

interface Ethernet1/6
  description CLIENT*LINKS2
  switchport mode trunk
  channel-group 40 mode active

interface Ethernet1/7
  description KEEPALIVE*LINK
  no switchport
  vrf member keepalive
  ip address 192.169.0.2/30
  no shutdown

interface Ethernet1/8
  description PEER*LINKS
  switchport mode trunk
  channel-group 1 mode active

interface Ethernet1/9
  description PEER*LINKS
  switchport mode trunk
  channel-group 1 mode active

router ospf 1
  network 10.10.20.0/24 area 0.0.0.1
  network 10.10.40.0/24 area 0.0.0.1
  network 172.0.1.0/24 area 0.0.0.1
  network 172.0.3.0/24 area 0.0.0.1

  end

  copy run start
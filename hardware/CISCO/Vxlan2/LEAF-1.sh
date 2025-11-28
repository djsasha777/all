hostname leaf1
install feature-set fabric
feature fabric forwarding
nv overlay evpn
feature ospf
feature bgp
feature pim
feature interface-vlan
feature fabric access
feature nv overlay
feature nv-segment-vlan-based

switching-mode store-forward

interface Ethernet1/23
 switchport mode trunk
 switchport trunk allowed vlan 1000-1001
 speed 1000

vlan 1

vlan 101
 vn-segment 900001

vlan 1000
 vn-segment 2001002

vlan 1001
 vn-segment 2001001

interface Vlan101
 no shutdown
 vrf member vxlan-900001
 ip forward

interface Vlan1000
 no shutdown
 mtu 9216
 vrf member vxlan-900001
 ip address 4.2.2.1/24
 ipv6 address 4:2:0:1::1/64
 fabric forwarding mode anicast-gateway

interface Vlan1001
 no shutdown
 mtu 9216
 vrf member vxlan-900001
 ip address 4.1.1.1/24
 ipv6 address 4:1:0:1::1/64
 fabric forwarding mode anicast-gateway

fabric forwarding anicast-gateway-mac 0000.2222.3333

ip pim rd-address 192.168.1.1 group-list 224.0.0.0/4
ip pim rd-address 192.168.1.2 group-list 224.0.0.0/4
ip pim ssm range 232.0.0.0/8
ip multicast multipath none

interface nve1
 no shutdown
 source-interface loopback0
 hosh-reachability protocol bgp
 member vni 900001 associate-vrf
 member vni 2001001
  suppress-arp
  mcast-group 239.0.0.1
 member vni 2001002
  suppress-arp
  mcast-group 239.0.0.1

interface Ethernet2/23
 no switchport
 ip address 172.16.1.2/24
 ip ospf network point-to-point
 ip router ospf 100 area 0.0.0.0
 ip pim sparse-mode

interface Ethernet2/24
 no switchport
 ip address 172.16.2.2/24
 ip ospf network point-to-point
 ip router ospf 100 area 0.0.0.0
 ip pim sparse-mode

interface loopback0
 ip address 172.16.1.3/24
 ip router ospf 100 area 0.0.0.0
 ip pim sparse-mode

router ospf 100
  router-id 192.168.1.3

router bgp 200
 router-id 192.168.1.3
 address-family ipv4 unicast
 address-family l2vpn evpn
 neighbor 192.168.1.1
  remote-as 200
  update-source loopback0
  address-family ipv4 unicast
  address-family l2vpn evpn
   send-community extended
 neighbor 192.168.1.2
  remote-as 200
  update-source loopback0
  address-family ipv4 unicast
  address-family l2vpn evpn
   send-community extended

evpn
 vni 2001001 l2
  rd auto
  route-target import auto
  route-target export auto
 vni 2001001 l2
  rd auto
  route-target import auto
  route-target export auto

vrf context vxlan-900001
 vni 900001
 rd auto
 address-family ipv4 unicast
  route-target both auto
  route-target both auto evpn
 address-family ipv6 unicast
  route-target both auto
  route-target both auto evpn
nv overlay evpn
feature ospf
feature bgp
feature vn-segment-vlan-based
feature nv overlay

ip igmp snooping vxlan
vlan 1,10
vlan 10
  vn-segment 1000

interface nve1
  no shutdown
  host-reachability protocol bgp
  source-interface loopback1
  member vni 1000
    suppress-arp
    mcast-group 239.0.0.1

interface Ethernet1/1
  ip address 10.10.10.1/30
  ip router ospf 1 area 0.0.0.0
  no shutdown

interface Ethernet1/2
  ip address 10.10.10.5/30
  ip router ospf 1 area 0.0.0.0
  no shutdown

interface Ethernet1/3
  switchport
  switchport access vlan 10
  no shutdown

interface loopback1
  ip address 1.1.1.1/32
  ip router ospf 1 area 0.0.0.0

router ospf 1
  router-id 1.1.1.1

router bgp 65000
  template peer iBGP-EVPN
    remote-as 65000
    update-source loopback1
    address-family l2vpn evpn
      send-community extended
  neighbor 2.2.2.2
    inherit peer iBGP-EVPN
  neighbor 3.3.3.3
    inherit peer iBGP-EVPN

evpn
  vni 1000 l2
    rd auto
    route-target import auto
    route-target export auto

nv overlay evpn
feature ospf
feature bgp
feature vn-segment-vlan-based
feature nv overlay

interface Ethernet1/1
  ip address 10.10.10.2/30
  ip router ospf 1 area 0.0.0.0
  no shutdown

interface Ethernet1/2
  ip address 10.10.10.9/30
  ip router ospf 1 area 0.0.0.0
  no shutdown

interface loopback1
  ip address 2.2.2.2/32
  ip router ospf 1 area 0.0.0.0

router ospf 1
  router-id 2.2.2.2

router bgp 65000
  template peer iBGP-EVPN
    remote-as 65000
    update-source loopback1
    address-family l2vpn evpn
      send-community extended
      route-reflector-client
  neighbor 1.1.1.1
    inherit peer iBGP-EVPN
  neighbor 4.4.4.4
    inherit peer iBGP-EVPN

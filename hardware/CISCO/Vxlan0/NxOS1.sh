
feature ospf
feature pim
feature interface-vlan
feature vn-segment-vlan-based
feature nv overlay

ip pim rp-address 4.4.4.4 group-list 224.0.0.0/4
ip pim ssm range 232.0.0.0/8

vlan 1000
vlan 1000
  vn-segment 5000

interface nve1
  no shutdown
  source-interface loopback1
  member vni 5000 mcast-group 230.1.1.1

interface Ethernet1/1
  ip address 10.10.10.1/24
  ip router ospf 1 area 0.0.0.0
  ip pim sparse-mode
  no shutdown

interface Ethernet1/3
  switchport
  switchport access vlan 1000
  no shutdown

interface loopback1
  ip address 1.1.1.1/32
  ip router ospf 1 area 0.0.0.0
  ip pim sparse-mode

router ospf 1
  router-id 1.1.1.1





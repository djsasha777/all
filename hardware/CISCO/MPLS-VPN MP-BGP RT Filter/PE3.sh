enable

conf t

hostname PE3

ip vrf VA3
 rd 65001:1
 route-target export 65001:1
 route-target import 65001:1

ip vrf VB3
 rd 65002:1
 route-target export 65002:1
 route-target import 65002:1

mpls label range 5000 5999

interface Loopback0
 ip address 10.0.0.5 255.255.255.255

interface Ethernet1/0
 ip address 10.10.3.2 255.255.255.0
 mpls ip
 no shutdown

interface Ethernet1/1
 ip vrf forwarding VA3
 ip address 192.168.13.1 255.255.255.0
 no shutdown

interface Ethernet1/2
 ip vrf forwarding VB3
 ip address 192.168.23.1 255.255.255.0
 no shutdown

router ospf 11 vrf VA3
 domain-id type 0005 value 0000000A0200
 redistribute bgp 65000 subnets
 network 192.168.13.0 0.0.0.255 area 3

router ospf 1
 network 10.0.0.0 0.255.255.255 area 0

router rip
 
 address-family ipv4 vrf VB3
  redistribute bgp 65000 metric 1
  network 192.168.23.0
  no auto-summary
 exit-address-family

router bgp 65000
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 10.0.0.3 remote-as 65000
 neighbor 10.0.0.3 update-source Loopback0
 neighbor 10.0.0.4 remote-as 65000
 neighbor 10.0.0.4 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 10.0.0.3 activate
  neighbor 10.0.0.3 send-community extended
  neighbor 10.0.0.4 activate
  neighbor 10.0.0.4 send-community extended
 exit-address-family
 
 address-family ipv4 vrf VA3
  redistribute ospf 11
 exit-address-family
 
 address-family ipv4 vrf VB3
  redistribute rip
 exit-address-family

end

wr

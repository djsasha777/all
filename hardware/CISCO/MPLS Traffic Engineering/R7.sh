
hostname R7

vrf definition V1
 rd 100:1
 route-target export 100:1
 route-target import 100:1
 
 address-family ipv4
 exit-address-family

bsd-client server url https://cloudsso.cisco.com/as/token.oauth2

mpls traffic-eng tunnels

interface Loopback0
 ip address 7.7.7.7 255.255.255.255

interface Tunnel0
 ip unnumbered Loopback0
 tunnel mode mpls traffic-eng
 tunnel destination 2.2.2.2
 tunnel mpls traffic-eng autoroute announce
 tunnel mpls traffic-eng path-option 1 explicit name TO_R2
 tunnel mpls traffic-eng fast-reroute
 no routing dynamic

interface Ethernet1/0
 bandwidth 1000000
 ip address 10.5.7.7 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

interface Ethernet1/1
 bandwidth 1000000
 vrf forwarding V1
 ip address 200.7.8.7 255.255.255.0
 duplex half

interface Ethernet1/2
 bandwidth 1000000
 ip address 10.6.7.7 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

router ospf 200 vrf V1
 redistribute bgp 100 subnets
 network 200.7.8.0 0.0.0.255 area 0

router ospf 1
 mpls traffic-eng router-id Loopback0
 mpls traffic-eng area 0
 network 7.7.7.7 0.0.0.0 area 0
 network 10.5.7.0 0.0.0.255 area 0
 network 10.6.7.0 0.0.0.255 area 0

router bgp 100
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 2.2.2.2 remote-as 100
 neighbor 2.2.2.2 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 2.2.2.2 activate
  neighbor 2.2.2.2 send-community extended
 exit-address-family
 
 address-family ipv4 vrf V1
  redistribute ospf 200 route-map R8L0
 exit-address-family

ip explicit-path name TO_R2 enable
 next-address 6.6.6.6
 next-address 5.5.5.5
 next-address 3.3.3.3
 next-address 2.2.2.2

ip prefix-list R8L0 seq 5 permit 8.8.8.8/32

route-map R8L0 permit 10
 match ip address prefix-list R8L0

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end
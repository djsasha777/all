
hostname R2

vrf definition V1
 rd 100:1
 route-target export 100:1
 route-target import 100:1
 
 address-family ipv4
 exit-address-family

bsd-client server url https://cloudsso.cisco.com/as/token.oauth2

multilink bundle-name authenticated
mpls traffic-eng tunnels

interface Loopback0
 ip address 2.2.2.2 255.255.255.255

interface Tunnel0
 ip unnumbered Loopback0
 tunnel mode mpls traffic-eng
 tunnel destination 7.7.7.7
 tunnel mpls traffic-eng autoroute announce
 tunnel mpls traffic-eng path-option 1 explicit name TO_R7
 tunnel mpls traffic-eng fast-reroute
 no routing dynamic

interface Ethernet1/0
 bandwidth 1000000
 ip address 10.2.3.2 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

interface Ethernet1/1
 bandwidth 1000000
 vrf forwarding V1
 ip address 100.1.2.2 255.255.255.0
 duplex half

interface Ethernet1/2
 bandwidth 1000000
 ip address 10.2.4.2 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

router ospf 100 vrf V1
 redistribute bgp 100 subnets
 network 100.1.2.0 0.0.0.255 area 0

router ospf 1
 mpls traffic-eng router-id Loopback0
 mpls traffic-eng area 0
 network 2.2.2.2 0.0.0.0 area 0
 network 10.2.3.0 0.0.0.255 area 0
 network 10.2.4.0 0.0.0.255 area 0

router bgp 100
 bgp log-neighbor-changes
 no bgp default ipv4-unicast
 neighbor 7.7.7.7 remote-as 100
 neighbor 7.7.7.7 update-source Loopback0
 
 address-family ipv4
 exit-address-family
 
 address-family vpnv4
  neighbor 7.7.7.7 activate
  neighbor 7.7.7.7 send-community extended
 exit-address-family
 
 address-family ipv4 vrf V1
  redistribute ospf 100 route-map R1L0
 exit-address-family

ip explicit-path name TO_R7 enable
 next-address 4.4.4.4
 next-address 6.6.6.6
 next-address 7.7.7.7

ip prefix-list R1L0 seq 5 permit 1.1.1.1/32

route-map R1L0 permit 10
 match ip address prefix-list R1L0

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end
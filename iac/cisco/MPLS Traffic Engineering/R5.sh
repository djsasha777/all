
hostname R5

bsd-client server url https://cloudsso.cisco.com/as/token.oauth2

mpls traffic-eng tunnels

interface Loopback0
 ip address 5.5.5.5 255.255.255.255

interface Tunnel1
 ip unnumbered Loopback0
 tunnel mode mpls traffic-eng
 tunnel destination 3.3.3.3
 tunnel mpls traffic-eng path-option 1 explicit name AVOID_R5_R3_ROUTE
 no routing dynamic

interface Ethernet1/0
 bandwidth 1000000
 ip address 10.5.7.5 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

interface Ethernet1/1
 bandwidth 1000000
 ip address 10.3.5.5 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 mpls traffic-eng backup-path Tunnel1
 ip rsvp bandwidth

interface Ethernet1/2
 bandwidth 1000000
 ip address 10.5.6.5 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

router ospf 1
 mpls traffic-eng router-id Loopback0
 mpls traffic-eng area 0
 network 5.5.5.5 0.0.0.0 area 0
 network 10.0.0.0 0.255.255.255 area 0

ip explicit-path name AVOID_R5_R3_ROUTE enable
 exclude-address 10.3.5.5
 exclude-address 10.3.5.3

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end
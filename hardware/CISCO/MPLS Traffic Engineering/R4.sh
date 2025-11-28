
hostname R4

bsd-client server url https://cloudsso.cisco.com/as/token.oauth2

mpls traffic-eng tunnels

interface Loopback0
 ip address 4.4.4.4 255.255.255.255

interface Ethernet1/0
 bandwidth 1000000
 ip address 10.3.4.4 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

interface Ethernet1/1
 bandwidth 1000000
 ip address 10.4.6.4 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

interface Ethernet1/2
 bandwidth 1000000
 ip address 10.2.4.4 255.255.255.0
 duplex half
 mpls traffic-eng tunnels
 ip rsvp bandwidth

router ospf 1
 mpls traffic-eng router-id Loopback0
 mpls traffic-eng area 0
 network 4.4.4.4 0.0.0.0 area 0
 network 10.0.0.0 0.255.255.255 area 0

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end
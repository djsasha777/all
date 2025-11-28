
hostname R8

bsd-client server url https://cloudsso.cisco.com/as/token.oauth2

multilink bundle-name authenticated

interface Loopback0
 ip address 8.8.8.8 255.255.255.255

interface Ethernet1/0
 bandwidth 1000000
 ip address 200.7.8.8 255.255.255.0
 duplex half

router ospf 200
 network 8.8.8.8 0.0.0.0 area 0
 network 200.7.8.0 0.0.0.255 area 0

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end

hostname R1

interface Loopback0
 ip address 1.1.1.1 255.255.255.255

interface Ethernet1/0
 bandwidth 1000000
 ip address 100.1.2.1 255.255.255.0
 duplex half

router ospf 100
 network 1.1.1.1 0.0.0.0 area 0
 network 100.1.2.0 0.0.0.255 area 0

mgcp behavior rsip-range tgcp-only
mgcp behavior comedia-role none
mgcp behavior comedia-check-media-src disable
mgcp behavior comedia-sdp-force disable

end
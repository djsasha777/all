#static routing configure
#for static routing you need to define static gateway throw next hope or directly connected interface

enable
conf t
ip route 172.5.1.0 255.255.252.0 70.70.71.2
ip route 0.0.0.0 0.0.0.0 70.70.70.1
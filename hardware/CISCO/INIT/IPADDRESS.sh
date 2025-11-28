#define ip address to interface

enable
conf t
int e0/1
ip address 195.1.1.1 255.255.255.0
duplex full
no shutdown
end
wr

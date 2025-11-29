# ip addressing 

cli
configure

# configure address for L3
set interfaces em5 unit 0 description MYINT1
set interfaces em5 unit 0 family inet address 10.10.22.2/24
set interfaces em6 unit 0 description MYINT2
set interfaces em6 unit 0 family inet address 10.10.12.2/24

# configure address for L2

set interfaces em3 description Master1
set interfaces em3 unit 0 family ethernet-switching port-mode access


#How to setup gateway or static route for Juniper:

set routing-options static route 0.0.0.0/0 next-hop 172.16.1.1
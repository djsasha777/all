# Script for check ip adresses in subnetwork
#!/bin/bash
if [ "$1" == "" ]
then
echo "You dont cpecify ip, specify like \"./myscript.sh 192.158.1\""
else
for ip in `seq 1 254` ; do
ping -c 1 $1.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" &
done
fi
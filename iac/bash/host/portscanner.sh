# Script for check open port of ip adresses of specified files
#!/bin/bash
if [ "$1" == "" ]
then
echo "You dont cpecify inpyt file, specify like \"./myscript.sh inputfile.txt\""
else
for ip in $(cat $1); 
do
nmap -p 80 -T4 $ip &
done
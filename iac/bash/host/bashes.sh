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

# Script to start services if not running
#!/bin/bash
ps -ef | grep nginx |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/nginx start > /dev/null
fi

# Script for checking global ip address and region
#!/bin/bash
apt update
apt install jq -y
ip=$(curl -s https://api.ipify.org)
echo "IP: $ip"
reg=$(curl -s http://ip-api.com/json/${ip} | jq -r '.countryCode')
echo "REGION: $reg"

# Script for comparsion of numbers
#!/bin/bash
a=$1
b=$2
if [[ ${a} -ge ${b} ]]; then
echo ${a} ">" ${b};
elif [[ ${a} -eq ${b} ]]; then
echo ${a} "=" ${b};
else
echo ${a} "<" ${b};
fi

# Script for multiply original notes of first column with "," devider in specified file
# usage ./divider.sh mytextfile.txt
#!/bin/bash
if [ "$1" == "" ]
then
echo "You dont cpecify infut file, specify like \"./divider.sh mytextfile.txt\""
else
cut -d, -f1 $1 | sort | uniq | wc -l
fi
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
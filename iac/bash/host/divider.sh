# Script for multiply original notes of first column with "," devider in specified file
# usage ./divider.sh mytextfile.txt
#!/bin/bash
if [ "$1" == "" ]
then
echo "You dont cpecify infut file, specify like \"./divider.sh mytextfile.txt\""
else
cut -d, -f1 $1 | sort | uniq | wc -l
fi
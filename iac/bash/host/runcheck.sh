# Script to start services if not running
#!/bin/bash
ps -ef | grep nginx |grep -v grep > /dev/null
if [ $? != 0 ]
then
       /etc/init.d/nginx start > /dev/null
fi
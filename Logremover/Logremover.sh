#!/bin/sh
#Made By K.T.H

nowtime=`date +%F-%T`
DiskSize=`df -h | grep "/$" | awk '{print $2}' | awk -F 'G' '{print int($1)}'`

date=`date +%F`

path="/usr/local/castis/tools/"
path1="/var/log/castis/"

mkdir -p $path
mkdir -p $path/log/

if [ $DiskSize -gt 100 ]
then
        echo "$nowtime" >> $path"log/"$date"_LogRemover.log"
        /usr/sbin/tmpwatch -m 1440 -a -q -v $path1 >> $path"log/"$date"_LogRemover.log"
else
        echo "$nowtime" >> $path"log/"$date"_LogRemover.log"
        /usr/sbin/tmpwatch -m 720 -a -q -v $path1 >> $path"log/"$date"_LogRemover.log"
fi
#!/bin/bash

ListFile2="all_ip.txt"
b="Big"
n="Nomal"
h="High"


rm -rf output.txt
perl -pi -e 's/\r//g' all_ip.txt

for list2 in `cat $ListFile2`
do
	/usr/local/castis/tools/SampleNetIODownloader $list2 /home/castis/20141230/all_network.txt /etc/sysconfig/network 10000000
	/usr/local/castis/tools/SampleNetIODownloader $list2 /home/castis/20141230/vod_size /usr/local/castis/vod.cfg 10000000

        
	size=`cat "vod_size" | grep -i "Bandwidth" | cut -d"=" -f2`
	place=`cat /home/castis/20141230/all_network.txt | grep "^H" | cut -d = -f 2 | cut -d - -f 1`
	vod=`cat /home/castis/20141230/all_network.txt | grep "^H" | cut -d = -f 2 | cut -d - -f 5`

       if [ "$size" = 1000000000 ]
          then
		echo "$place,$vod,$list2,$b" >> /home/castis/20141230/output.txt >&1 2>&1
          elif [ "$size" = 7000000000 ]
          then
		echo "$place,$vod,$list2,$h" >> /home/castis/20141230/output.txt >&1 2>&1
          else
		echo "$place,$vod,$list2,$n" >> /home/castis/20141230/output.txt >&1 2>&1
          fi
         sleep 1


  	
	rm -rf all_network.txt
	rm -rf vod_size
	
done 

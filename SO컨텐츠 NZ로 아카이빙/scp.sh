#!/bin/bash

#cur_time=`date +%F,%T`
remote_ip=172.16.21.106

cd /home/castis/20150312/

while true
sleep 5
do
        for file in `ls -l | grep .mpg | awk '{print $9}'`
	do
		/home/castis/20150312/scp_expect.sh $file $remote_ip
		sleep 2
		/home/castis/20150312/ssh_expect.sh $remote_ip $file | grep -v spawn | grep -v root > .temp_size
		sleep 15
		dos2unix .temp_size
		sleep 2
		remote_size=`cat .temp_size`
		cur_size=`ls -l | grep $file | awk '{print $5}'`
		
		while [ $remote_size -eq $cur_size ]
		do
		if [ $remote_size -lt $cur_size ]
		then
			continue;
		else
			cur_time=`date +%F,%T`
			rm -rf $file
			echo $cur_time,$file >> /home/castis/20150312/remove_file.txt
			break
		fi
		done
	done
done

#!/bin/bash

Year=2015
Month=12
StartDay=03
EndDay=10


for place in `cat IP_LIST | grep -v '#'`
do
	name=`echo $place | cut -d, -f1`
	ip=`echo $place | cut -d, -f2`
	
	mkdir -p result/$name/lb  2> /dev/null
	mkdir -p result/$name/srm 2> /dev/null
	mkdir -p result/$name/vod 2> /dev/null
	
	#lb
	for day in `seq -w $StartDay $EndDay`
	do
		./expect.sh $ip "/var/log/castis/lb/$Year-$Month/$Year-$Month-$day*" result/$name/lb
		sleep 1
	done
	
	#srm
	for day in `seq -w $StartDay $EndDay`
        do
                ./expect.sh $ip "/var/log/castis/srm/$Year-$Month/$Year-$Month-$day*" result/$name/srm
                sleep 1
        done
	
	#vod
	./expect.sh $ip "/usr/local/castis/CiLoadBalancer.cfg" result/$name/vod/CiLoadBalancer.cfg
	dos2unix result/$name/vod/CiLoadBalancer.cfg

	for vod_server in `cat result/$name/vod/CiLoadBalancer.cfg | egrep ^'Server' | grep -v '#' | grep -v Priority | cut -d'=' -f2`
	do
		Dest=`echo $vod_server | cut -d'.' -f4`
		for day in `seq -w $StartDay $EndDay`
		do
			mkdir -p result/$name/vod/$Dest
			./expect.sh $vod_server "/var/log/castis/vod/EventLog[$Year$Month$day].log" result/$name/vod/$Dest
			sleep 1
		done
        done
	

done
#!/bin/bash

VOD1=192.168.43.151
VOD2=192.168.43.152
VOD3=192.168.43.153
VOD4=192.168.43.154
VOD5=192.168.43.155
VOD6=192.168.43.156
VOD7=192.168.43.157
VOD8=192.168.43.158

dirname=`dirname $0`

#Source Down
for ip in `cat $0 | grep VOD | grep -v "#" | grep -v "|" | grep -v "/" | cut -d= -f2`
do
        VOD_name=`cat $0 | grep $ip | cut -d= -f1`
        for((i=1;i<=2;i++))
        do
                $dirname/expect.sh $ip "ls /data$i" | grep -v spawn | grep -v pass | grep -v ATTEMPT >> $dirname/."$VOD_name"_file_list_temp
        done
        cat $dirname/."$VOD_name"_file_list_temp | sort | uniq >> $dirname/"$VOD_name"_file_list
        dos2unix $dirname/"$VOD_name"_file_list
        rm -f $dirname/."$VOD_name"_file_list_temp
done

#exclude node
for ip in `cat $0 | grep VOD | grep -v "#" | grep -v "|" | grep -v "/" | cut -d= -f2`
do
        VOD_name=`cat $0 | grep $ip | cut -d= -f1`
        cat `ls $dirname | grep _file_list | grep -v $VOD_name` >> $dirname/.exclude_$VOD_name
        cat $dirname/.exclude_$VOD_name | sort | uniq >> $dirname/exclude_$VOD_name
        dos2unix $dirname/exclude_$VOD_name
        rm -f $dirname/.exclude_$VOD_name
done

#Compare
for ip in `cat $0 | grep VOD | grep -v "#" | grep -v "|" | grep -v "/" | cut -d= -f2`
do
        VOD_name=`cat $0 | grep $ip | cut -d= -f1`
        for exclude_node in `cat $dirname/"$VOD_name"_file_list`
        do
                cat exclude_$VOD_name | grep $exclude_node > /dev/null 2> /dev/null
                if [ $? -eq 1 ]
                then
                        echo $exclude_node >> $dirname/Only_$VOD_name
                fi
        done
done
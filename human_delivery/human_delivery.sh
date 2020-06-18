#!/bin/bash

#####config#####
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
bash_path=/home/castis/human_delivery
tool_path=/usr/local/castis/tools
Log_Directory=$bash_path/log
GA_Node=192.168.34.200,/data1,192.168.34.220
SR_Node=192.168.124.140,/data1,192.168.124.152
KH_Node=192.168.117.140,/data1,192.168.117.146
BS_Node=192.168.118.140,/data1,192.168.118.150
CB_Node=192.168.113.50,/data1,192.168.113.60
PH_Node=192.168.123.140,/data1,192.168.123.147
Copy_Bitrate=100000000
###############

#####date#####
today=`date '+%Y%m%d' -d '1 day ago'`
cur_time=`date +%F,%T`
month=`date +%F`
##############

log(){

cur_time=`date +%F,%T`
echo "GFM_back,$cur_time,$1,$2/$3" >> $Log_Directory/"$month".log

}

[ ! -d $Log_Directory ] && mkdir -p $Log_Directory

#if [ ! -e "$bash_path"/EventLog\["$today"\].log_$hour ]
#then
#       $tool_path/SampleNetIODownloader 192.168.35.121 "$bash_path"/EventLog\["$today"\].log_$hour /var/log/castis/lb/EventLog\["$today"\].log 10000000
#       sleep 2
#fi

Main(){

#       if [ -e $bash_path/"$today"_"$1"_all_list ]
#       then
#               $tool_path/SampleNetIODownloader 192.168.35.121 "$bash_path"/EventLog\["$today"\].log_$hour /var/log/castis/lb/EventLog\["$today"\].log 10000000
#               cat $bash_path/EventLog\["$today"\].log_$hour | grep $1 | cut -d"(" -f2 | cut -d")" -f1 | sort | uniq -c | sort -nr | awk '$1 >= 4 {print $1,$2}' >> $bash_path/"$today"_"$1"_list_"$hour"
#               cat $bash_path/"$today"_"$1"_list_$hour | awk '{print $2}' >> $bash_path/"$today"_"$1"_list_temp_"$hour"
#               
#                       for list in `cat $bash_path/"$today"_"$1"_list_temp_$hour`
#                       do
#                               cat $bash_path/"$today"_"$1"_all_list | grep -w $list > /dev/null 2> /dev/null
#                               if [ $?  -eq 1 ]
#                               then
#                                       echo $list >> $bash_path/"$today"_"$1"_list_mpg_$hour
#                               fi
#                       done
#
#               sleep 20
#
#               for file in `cat $bash_path/"$today"_"$1"_list_mpg_$hour`
#                do
#                        $tool_path/SampleNetIOUploader $3 /sdata/$file $2/$file $Copy_Bitrate
#               
#                       if [ $? -eq 0 ] 
#                       then
#                               log $3 $2 "$file Move Success"
#                       else
#                               log $3 $2 "$file Move Fail"
#                       fi
#                
#               done
#               cat $bash_path/"$today"_"$1"_list_temp_$hour >> $bash_path/"$today"_"$1"_all_list
#
#       else
                cat $bash_path/EventLog\["$today"\].log | grep $1 | cut -d"(" -f2 | cut -d")" -f1 | sort | uniq -c | sort -nr | awk '$1 >= 4 {print $1,$2}' >> $bash_path/"$today"_"$1"_list
                cat $bash_path/"$today"_"$1"_list | awk '{print $2}' >> $bash_path/"$today"_"$1"_list_mpg
                cat $bash_path/"$today"_"$1"_list_mpg >> $bash_path/"$today"_"$1"_all_list

                for file in `cat $bash_path/"$today"_"$1"_list_mpg`
                do
                        $tool_path/SampleNetIOUploader $3 /sdata/$file $2/$file $Copy_Bitrate
                        if [ $? -eq 0 ]
                        then
                                log $3 $2 "$file Move Success"
                        else
                                log $3 $2 "$file Move Fail"
                        fi
                done
#       fi

}
echo "GFM_back,$cur_time,START!!!!!" >> $Log_Directory/"$month".log

$tool_path/SampleNetIODownloader 192.168.35.121 $bash_path/EventLog\["$today"\].log /var/log/castis/lb/EventLog\["$today"\].log 10000000 2> $bash_path/.log.check

if [ -e $bash_path/EventLog\["$today"\].log ]
then
        echo "GFM_back,$cur_time,EventLog Download Success" >> $Log_Directory/"$month".log
else
        echo "GFM_back,$cur_time,EventLog Download Fail" >> $Log_Directory/"$month".log
fi

for list in `cat "$bash_path"/human_delivery.sh | grep Node | grep -v "#"| grep -v "|" | cut -d= -f2 |  cut -d, -f1`
do
        path=`cat "$bash_path"/human_delivery.sh | grep $list | cut -d, -f2`
        remote_ip=`cat "$bash_path"/human_delivery.sh | grep $list | cut -d, -f3`
        Main $list $path $remote_ip &
done

#temp === _hour
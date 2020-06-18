#!/bin/bash

#####Config#####

tool_path=/usr/local/castis/tools
Server_Count=2
Server0_Address=172.16.11.5,/data1
Server1_Address=172.16.0.253,/data1
Log_Directory=/var/log/castis/Simple
Watch_Period_Sec=5
Watch_Directory=/home/castis/Push_test
Max_Count=1
Copy_Bitrate=300000000
Copy_Count=1

###############

version=SimpleContentDeliver_v1.0.2

script=$0
Count_check=1

Copy_log(){

cat $Log_Directory/.log_result.txt | grep Fail > /dev/null 2> /dev/null
if [ $? -eq 1 ]
then
        log $1 " -> $2:$3 Copy Success" Success
        echo $1 Success >> $Watch_Directory/.log_temp
else
        log $1 " -> $2:$3 Copy Fail. Change Dst" Fail
        echo $1 Fail >> $Watch_Directory/.log_temp
fi

}

log(){

cur_time=`date +%F,%T`
year_month=`date +%Y-%m`
today=`date +%F`

[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

echo "$version,$cur_time,$3,$1$2" >> $Log_Directory/$year_month/"$today".log

}

count_check(){

if [ $Count_check -gt $Server_Count ]
then
        Count_check=1
fi

}

rm_file(){

if [ $? -eq 0 ]
then
        rm -f $Watch_Directory/$1
fi

}

###Main###
year_month=`date +%Y-%m`

[ ! -d $Watch_Directory ] && mkdir -p $Watch_Directory
[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

log SimpleContentDeliver " Start" Information

while true
do
        sleep $Watch_Period_Sec
        count=`ls $Watch_Directory | grep .mpg | wc -l`
        if [ $count -ge $Max_Count ]
        then
                ls $Watch_Directory | grep .mpg > $Watch_Directory/.remote_move_list

                for list in `cat $Watch_Directory/.remote_move_list`
                do
                        for((i=1;i<=$Copy_Count;i++))
                        do
                                log $list ",find" Information
                                ip=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f1 | sed -n "$Count_check"p`
                                remote_dir=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f2 | sed -n "$Count_check"p`
                                log $list " -> $ip:$remote_dir Copy Start" Information
                                $tool_path/SampleNetIOUploader $ip $Watch_Directory/$list $remote_dir/$list $Copy_Bitrate 2> $Log_Directory/.log_result.txt
                                Copy_log $list $ip $remote_dir
                                let Count_check+=1
                                count_check
                        done

                        today=`date +%F`
                        year_month=`date +%Y-%m`

                        Copy_check=`cat $Watch_Directory/.log_temp | grep $list | grep Fail | wc -l` 2> /dev/null

                        if [ $Copy_check -lt $Copy_Count ]
                        then
                                rm_file $list
                                log $list ",Copy Result is Success, Remove $list" Success
                        else
                                log $list ",Copy Result is Fail, Change Dst" Fail
                        fi

                        rm -f $Watch_Directory/.log_temp

                done
        else
                continue
        fi
done
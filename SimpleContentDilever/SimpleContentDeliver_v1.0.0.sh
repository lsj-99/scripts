#!/bin/bash

#####config#####
#version v1.0.0

tool_path=/usr/local/castis/tools
Server_Count=10
#Server0_Address=192.168.35.141,/data1
#Server1_Address=192.168.35.142,/data1
Server0_Address=192.168.118.141,/data1
Server1_Address=192.168.118.142,/data1
Server2_Address=192.168.118.143,/data1
Server3_Address=192.168.118.144,/data1
Server4_Address=192.168.118.145,/data1
Server5_Address=192.168.118.146,/data1
Server6_Address=192.168.118.147,/data1
Server7_Address=192.168.118.148,/data1
Server8_Address=192.168.118.149,/data1
Server9_Address=192.168.118.150,/data1
Log_Directory=/var/log/castis/Simple
Watch_Period_Sec=5
Watch_Directory=/sdata/upload
Temp_Directory=/sdata/upload/scd_temp
Max_Count=2
Delete_CopyDone_File=1
Move_Folder_CopyDone_File=/sdata
Copy_Bitrate=120000000
Copy_Count=1

###############

script=$0
Count_check=1


start_log(){

cur_time=`date +%F,%T`
year_month=`date +%Y-%m`
today=`date +%F`

echo "SimpleDelivery,$cur_time,Start!!" >> $Log_Directory/$year_month/"$today".log

}

log(){

[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

cur_time=`date +%F,%T`
year_month=`date +%Y-%m`
today=`date +%F`

cat $Log_Directory/.log_result.txt | grep Fail > /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        echo "SimpleDelivery,$cur_time,$1,$2,Copy to $3 Fail! Change dst" >> $Log_Directory/$year_month/"$today".log
else
        echo "SimpleDelivery,$cur_time,$1,$2,Copy to $3 Success! $4 $1" >> $Log_Directory/$year_month/"$today".log
fi

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
        rm -f $Temp_Directory/$1
fi

}

mv_file(){

if [ $? -eq 0 ]
then
        mv -f $Temp_Directory/$1 $Move_Folder_CopyDone_File
fi

}

###Main###
year_month=`date +%Y-%m`

[ ! -d $Watch_Directory ] && mkdir -p $Watch_Directory
[ ! -d $Temp_Directory ] && mkdir -p $Temp_Directory
[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

mv -f $Temp_Directory/*.mpg $Watch_Directory > /dev/null 2> /dev/null

start_log

while true
do

today=`date +%F`
year_month=`date +%Y-%m`

sleep $Watch_Period_Sec
cd $Watch_Directory
count=`ls *.mpg | wc -l`
if [ $count -ge $Max_Count ]
then
        mv $Watch_Directory/*.mpg $Temp_Directory
        cd $Temp_Directory
        ls *.mpg > $Temp_Directory/.remote_move_list.txt

        for((i=1;i<=$Copy_Count;i++))
        do
                for list in `cat $Temp_Directory/.remote_move_list.txt`
                do
                        ip=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f1 | sed -n "$Count_check"p`
                        remote_dir=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f2 | sed -n "$Count_check"p`
                        $tool_path/SampleNetIOUploader $ip $Temp_Directory/$list $remote_dir/$list $Copy_Bitrate 2> $Log_Directory/.log_result.txt
                        if [ $Delete_CopyDone_File -eq 1 ]
                        then
                                log $list $ip $remote_dir "Remove"
                        else
                                log $list $ip $remote_dir "Move to $Move_Folder_CopyDone_File"
                        fi
                        let Count_check+=1
                        count_check
                done
        done

        remote_count=`cat $Temp_Directory/.remote_move_list.txt | wc -l`

        for((j=1;j<=$remote_count;j++))
        do
                mpg_name=`cat $Temp_Directory/.remote_move_list.txt | sed -n "$j"p`
                Copy_check=`cat $Log_Directory/$year_month/"$today".log | grep $mpg_name | tail -"$Copy_Count" | grep Success | wc -l`
                if [ $Delete_CopyDone_File -eq 0 ]
                then
                        if [ $Copy_check -ge 1 ]
                        then
                                mv_file $mpg_name
                        else
                                mv -f $Temp_Directory/$mpg_name $Watch_Directory > /dev/null 2> /dev/null
                        fi
                else
                        if [ $Copy_check -ge 1 ]
                        then
                                rm_file $mpg_name
                        else
                                mv -f $Temp_Directory/$mpg_name $Watch_Directory > /dev/null 2> /dev/null
                        fi
                fi
        done
else
        continue
fi

done
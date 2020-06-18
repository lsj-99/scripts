#!/bin/bash

#####config#####

Server_Count=2
Server0_Address=192.168.43.18,/root/test
Server1_Address=192.168.43.120,/root/test
Log_Directory=/var/log/castis/scd_log
Watch_Period_Sec=5
Watch_Directory=/root/test/temp
Temp_Directory=/root/test/temp/copy_temp
Max_Count=3
Delete_CopyDone_File=1
Move_Folder_CopyDone_File=/sdata
tool_path=/usr/local/castis/tools
hitcount_path=/data2/FailOver/.hitcount.history
Copy_Bitrate=120000000
Copy_Count=1

###############

version=SimpleContentDeliver_v1.0.4
Representative_IP_Address=`cat /usr/local/castis/CiLoadBalancer.cfg | grep Repre | cut -d'=' -f2`

script=$0
Count_check=1

Copy_log(){

cat $Log_Directory/.log_result.txt | grep Fail > /dev/null 2> /dev/null
if [ $? -eq 1 ]
then
        log Success "$Temp_Directory/$1" " -> $2:$3/$1 Copy Success"
        echo $1 Success >> $Temp_Directory/.log_temp
else
        log Fail "$Temp_Directory/$1" " -> $2:$3/$1 Copy Fail. Change Dst"
        echo $1 Fail >> $Temp_Directory/.log_temp
fi

}

log(){

cur_time=`date +%F,%T`
year_month=`date +%Y-%m`
today=`date +%F`

[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

echo "$version,$cur_time,$1,$2,$3" >> $Log_Directory/$year_month/"$today".log

}

count_check(){

if [ $Count_check -gt $Server_Count ]
then
        Count_check=1
fi

}

Check_Already_Registered(){

rm -f $Temp_Directory/.remote_move_list 2> /dev/null

for list in `cat $1`
do

        cat $hitcount_path | grep $list > /dev/null 2> /dev/null
        if [ $? -eq 0 ]
        then
                log Information $list "Already_Registered in Hitcount"
                /usr/local/castis/tools/LBFileDel/LBFileDel $Representative_IP_Address $list
                #rm -f $Temp_Directory/$list
                echo $list >> $Temp_Directory/.remote_move_list
        else
                echo $list >> $Temp_Directory/.remote_move_list
        fi

done

}

rm_file(){

rm -f $Temp_Directory/$1

}

mv_file(){

mv -f $Temp_Directory/$1 $Move_Folder_CopyDone_File

}

###Main###
year_month=`date +%Y-%m`

[ ! -d $Watch_Directory ] && mkdir -p $Watch_Directory
[ ! -d $Temp_Directory ] && mkdir -p $Temp_Directory
[ ! -d $Log_Directory/$year_month ] && mkdir -p $Log_Directory/$year_month

[ $Copy_Count -gt $Server_Count ] && log Error "Copy_Count is bigger than Server_Count. Check config"
[ $Copy_Count -gt $Server_Count ] && echo "Copy_Count is bigger than Server_Count. Check config"
[ $Copy_Count -gt $Server_Count ] && exit

mv -f $Temp_Directory/*.mpg $Watch_Directory 2> /dev/null
mv -f $Temp_Directory/*.MPG $Watch_Directory 2> /dev/null
mv -f $Temp_Directory/*.ts $Watch_Directory 2> /dev/null

log Information "SimpleConetentDeliver" start
while true
do
        sleep $Watch_Period_Sec
        count=`ls $Watch_Directory | egrep '.mpg|.MPG|*.ts' | wc -l`
        if [ $count -ge $Max_Count ]
        then
                mv $Watch_Directory/*.mpg $Temp_Directory 2> /dev/null
		mv $Watch_Directory/*.MPG $Temp_Directory 2> /dev/null
		mv $Watch_Directory/*.ts $Temp_Directory 2> /dev/null
                ls $Temp_Directory | egrep '.mpg|.MPG|*.ts' > $Temp_Directory/.remote_move_list_temp
                Check_Already_Registered $Temp_Directory/.remote_move_list_temp

                for list in `cat $Temp_Directory/.remote_move_list`
                do
                        for((i=1;i<=$Copy_Count;i++))
                        do
                                log Information "$list" "find"
                                ip=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f1 | sed -n "$Count_check"p`
                                remote_dir=`cat $script | grep Address | grep -v "#" | cut -d= -f2 | cut -d, -f2 | sed -n "$Count_check"p`
                                log Information "$Temp_Directory/$list -> $ip:$remote_dir/$list" "Start"
                                $tool_path/SampleNetIOUploader $ip $Temp_Directory/$list $remote_dir/$list $Copy_Bitrate 2> $Log_Directory/.log_result.txt
                                Copy_log $list $ip $remote_dir
                                let Count_check+=1
                                count_check
                        done

                        Fail_check=`cat $Temp_Directory/.log_temp | grep $list | grep Fail | wc -l`

                        if [ $Delete_CopyDone_File -eq 0 ]
                        then
                                if [ $Fail_check -ge 1 ]
                                then
                                        mv -f $Temp_Directory/$list $Watch_Directory > /dev/null 2> /dev/null
                                        log Fail "$list" "Copy Result is Fail, Change Dst"
                                else
                                        mv_file $list
                                        log Information "$list" "Copy Result is Success, Move $Move_Folder_CopyDone_File/$list"
                                fi
                        else
                                if [ $Fail_check -ge 1 ]
                                then
                                        mv -f $Temp_Directory/$list $Watch_Directory > /dev/null 2> /dev/null
                                        log Fail "$list" "Copy Result is Fail, Change Dst"
                                else
                                        rm_file $list
                                        log Information "$list" "Copy Result is Success, Remove $Temp_Directory/$list"
                                fi
                        fi
                        rm -f $Temp_Directory/.log_temp
                done
        else
                continue
        fi
done
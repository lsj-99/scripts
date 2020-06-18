#!/bin/bash

Node_name=TEST1
Dir_Count=3
PollingDirs[0]=/data/upload
PollingDirs_check_count[0]=5
PollingDirs[1]=/data/upload/scd_temp
PollingDirs_check_count[1]=5
PollingDirs[2]=/data/upload/temp
PollingDirs_check_count[2]=5

#log dir
log_dir=/var/log/castis/check_monitor
scd_log_dir=/var/log/castis/Simple
ADSController_log_dir=/var/log/castis/ADSController_Log
tool_path=/usr/local/castis/tools

#Master_Server_upload
Master_Server_upload=on
Master_Server_IP=172.16.18.204
Master_Server_Dir=/root/temp

########################################

year=`date +%Y`
month=`date +%m`
day=`date +%d`


log(){
# $1 = discription
# $2 = echo option

echo $2 "$1" >> $log_dir/$year-$month/$year-$month-$day"_$Node_name".log

}

Count_Check(){
log '########Count Check########' 

for((i=0;i<$Dir_Count;i++))
do
        count=`ls ${PollingDirs[$i]}| grep mpg | wc -l`

        log "${PollingDirs[$i]} : $count"
        if [ $count -ge ${PollingDirs_check_count[$i]} ]
        then
                Check_state[$i]=1
        fi
done

echo ${Check_state[@]} | grep 1 > /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        log 'Dir_Count_state=Warning'
else
        log 'Dir_Count_state=OK'
fi

log " "

}

Scd_Copy_Check(){
log '######scd Copy Check(Uniq Success)######' 

if [ ! -s $scd_log_dir/$year-$month/$year-$month-$day.log ]
then
        log "There are no scd log"
        log "scd_Copy_state=OK"

        log " "
else

        scd_Success_Count=`cat $scd_log_dir/$year-$month/$year-$month-$day.log | grep Success | cut -d" " -f6 | sort | uniq | wc -l`
        scd_Fail_Count=`cat $scd_log_dir/$year-$month/$year-$month-$day.log | grep Fail | cut -d, -f4 | sort | uniq | wc -l`

        log "scd_Copy_Success_Count : $scd_Success_Count"
        log "scd_Copy_Fail_Count : $scd_Fail_Count"
        if [ $scd_Fail_Count == 0 ]
        then
                log 'scd_Copy_state=OK'
        else
                log 'scd_Copy_state=Warning'
        fi

        log " "

fi
}

vodstate_Check(){
log '######vodstatus Check######' 

log "`$tool_path/vodcmd all status | grep -v "Status OK"`"
vod_Error_Count=`$tool_path/vodcmd all status | grep vod | grep Error | wc -l`
if [ $vod_Error_Count -ge 1 ]
then
        log 'vodcmd_state=Warning'
else
        log 'vodcmd_state=OK'
fi

log " "

}

ADSController_Success_Check(){

log '######ADSController_Success_Check######'

ADSC_Success_Count=`cat $ADSController_log_dir/$year-$month/$year-$month-$day* | grep "Transmission Success" | grep block+filelive | wc -l`
ADSC_Fail_Count=`cat $ADSController_log_dir/$year-$month/$year-$month-$day* | grep "Transmission Fail" | grep block+filelive | wc -l`

log "ADSController_Success_Count : $ADSC_Success_Count"
log "ADSController_Fail_Count : $ADSC_Fail_Count"

if [ $ADSC_Fail_Count == 0 ]
then
        log 'ADSController_state=OK'
else
        log 'ADSController_state=Warning'
fi

log " "

}

Master_Server_upload_check(){

if [ $Master_Server_upload = on ]
then
        $tool_path/SampleNetIOUploader $Master_Server_IP $log_dir/$year-$month/$year-$month-$day"_$Node_name".log $Master_Server_Dir/$year-$month-$day"_$Node_name".log 10000000 2> /dev/null
fi

}

[ ! -d $log_dir/$year-$month ] && mkdir -p $log_dir/$year-$month

check_time=`date +%F,%T`
log "-------------------------------$Node_name $check_time state-------------------------------"

log " "

Count_Check
Scd_Copy_Check
ADSController_Success_Check
vodstate_Check
Master_Server_upload_check
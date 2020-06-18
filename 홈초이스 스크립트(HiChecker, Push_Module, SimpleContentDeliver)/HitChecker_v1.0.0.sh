#!/bin/bash

#####Config#####

Frozen_IP=10.35.8.70
Frozen_Hitcount_Path=/data1/FailOver
Relay_Lb_Log_Path=/var/log/castis/lb_log
LogCollect_In_Day=1
Content_Hit=15
Job_Path=/home/castis/HitChecker
Log_Path=/home/castis/HitChecker/log
Backup_Dir=/home/castis/HitChecker/Backup
Tool_Path=/usr/local/castis/tools

#Move Option
Move_result_file=0
Result_File_Path=/data/FailOver

################

version=HitChecker_v1.0.0

Dir_Check(){

year=`date +%Y`
month=`date +%m`

[ ! -d $Backup_Dir ] && mkdir -p $Backup_Dir
[ ! -d $Job_Path ] && mkdir -p $Job_Path
[ ! -d $Log_Path/$year-$month ] && mkdir -p $Log_Path/$year-$month

}

Log(){

today=`date +%Y-%m-%d`
cur_time=`date +%F,%T`
year=`date +%Y`
month=`date +%m`

echo $version,$cur_time,$3,$1,$2 >> $Log_Path/$year-$month/$today.log

}

Hitcount_Download(){

$Tool_Path/SampleNetIODownloader_New $Frozen_IP $Job_Path/.Hitcount $Frozen_Hitcount_Path/.hitcount.history 1000000 2> $Job_Path/.down_result
cat $Job_Path/.down_result | grep -i fail > /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        Log Hitcount "DownLoad Fail" Fail
        echo "Hitcount Download Fail!"
        Log HitChecker Finish Information
        exit
else
        Log Hitcount "DownLoad Success" Success
fi

}

Log_Collect(){

Log "Log_Collect($LogCollect_In_Day day)" Start Information

for((i=0;i<=$LogCollect_In_Day;i++))
do
        date=`date +%Y%m%d -d "$i day ago"`

        cp $Relay_Lb_Log_Path/EventLog[$date].log $Job_Path
        if [ -s $Job_Path/EventLog[$date].log ]
        then
                Log EventLog[$date].log "Copy Success" Success
        else
                Log EventLog[$date].log "Copy Fail" Fail
        fi
done

Log Log_Collect Finish Information

}

Backup(){

today=`date +%Y%m%d%H%M`

cp $1 $Backup_Dir/hitfailcount.history_$today
if [ -s $Backup_Dir/hitfailcount.history_$today ]
then
        Log hitfailcount "Backup Success" Success
else
        Log hitfailcount "Backup Fail" Fail
fi

}

Result_Check(){

if [ ! -s $Job_Path/hitfailcount.history ]
then
        Log hitfailcount.history "There are no result file" Error
        rm -f $Job_Path/EventLog*
        echo "There are no result file"
        Log "Create hitfailcount" Finish Information
        Log HitChecker Finish Information
        exit

fi

}

Main(){

cat $Job_Path/EventLog* | grep Request | cut -d"(" -f2 | cut -d")" -f1 | sort | uniq -c | awk -v Content_Hit=$Content_Hit '$1 >= Content_Hit {print $1,$2}' > $Job_Path/.all_hit
cat $Job_Path/.Hitcount | cut -d, -f1 > $Job_Path/.Hitcount_mpg
cat $Job_Path/EventLog* | sort > $Job_Path/.EventLog_sort

rm -f $Job_Path/.hitfailcount_temp > /dev/null 2> /dev/null
for list in `cat $Job_Path/.all_hit | awk '{print $2}'`
do

        cat $Job_Path/.Hitcount_mpg | grep -x $list > /dev/null 2> /dev/null
        if [ $? -eq 1 ]
        then
                mpg=`cat $Job_Path/.all_hit | grep $list | head -1`
                echo $mpg >> $Job_Path/.hitfailcount_temp
        fi

done

Log "Create hitfailcount" Start Information

all_hit_count=`cat $Job_Path/.hitfailcount_temp | wc -l`
rm -f $Job_Path/hitfailcount.history 2> /dev/null
for((i=1;i<=$all_hit_count;i++))
do
        count=`cat $Job_Path/.hitfailcount_temp | awk '{print $1}' | sed -n "$i"p`
        mpg=`cat $Job_Path/.hitfailcount_temp | awk '{print $2}' | sed -n "$i"p`
        date=`cat $Job_Path/.EventLog_sort | grep $mpg | tail -1 | awk -F , '{print $3}'`
        echo "$mpg,$date=$count $count" >> $Job_Path/hitfailcount.history
done

Result_Check

Log "Create hitfailcount" Finish Information

rm -f $Job_Path/EventLog*

Backup $Job_Path/hitfailcount.history

if [ $Move_result_file -eq 0 ]
then
        mv -f $Job_Path/hitfailcount.history $Result_File_Path/.hitfailcount.history # << NEET TO CHANGE ex)) .hitfailcount.history_test > .hitfailcount.history
fi

Log HitChecker Finish Information

}

Dir_Check
Log HitChecker Start Information
Hitcount_Download
Log_Collect
Main
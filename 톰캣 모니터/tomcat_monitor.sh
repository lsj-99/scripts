#!/bin/bash

#########################################
log_path=/usr/local/tomcat/logs/LogAggregator
watch_period_sec=3
sleep_period_sec=3600
result_path=/var/log/castis/tomcat_monitor
########################################

log(){

date=`date +%F,%T`
log_date=`date +%Y-%m-%d`

echo $date,"Found OutOfMemory So kill tomcat" >> $result_path/$log_date.log

}

while true
do
        sleep $watch_period_sec
        cat $log_path/LogAggregator.log | grep "OutOfMemoryError" > /dev/null 2> /dev/null
        if [ $? -eq 0 ]
        then
                log
                /usr/local/castis/killtomcat.sh
                sleep $sleep_period_sec
        else
                continue
        fi
done
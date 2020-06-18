#!/bin/sh

cpu_idle=`vmstat 2 2 | tail -n 1 | awk '{print $15}'`
[ `getconf LONG_BIT` -eq 32 ] && vod_pid=`pidof IPVODServer2`
[ `getconf LONG_BIT` -eq 64 ] && vod_pid=`pidof CiHVODServer`
vmpeak=`grep VmPeak /proc/$vod_pid/status | awk '{print $2}'`
vmsize=`grep VmSize /proc/$vod_pid/status | awk '{print $2}'`

today=`date +%Y%m%d`
year=`date +%Y`
month=`date +%m`
day=`date +%d`
err_log=`grep -c -i err /var/log/castis/vod_log/EventLog[$today].log`
fail_log=`grep -c -i fail /var/log/castis/vod_log/EventLog[$today].log`
nomedia=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'No Media'`
reset=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'Reset'`
session=`cat /var/run/civod/session.count`
process=`ps -eo lstart,comm |grep VOD | head -n 1 | awk '{print $4}'`

echo "`hostname` `date +%F,%T` $cpu_idle $vmpeak $vmsize $err_log $fail_log $nomedia $reset $session $process" >> /home/castis/log/$today.check.log





백업
===============================
송파


#!/bin/sh

cpu_idle=`vmstat 2 2 | tail -n 1 | awk '{print $15}'`
[ `getconf LONG_BIT` -eq 32 ] && vod_pid=`pidof IPVODServer2`
[ `getconf LONG_BIT` -eq 64 ] && vod_pid=`pidof CiHVODServer`
vmpeak=`grep VmPeak /proc/$vod_pid/status | awk '{print $2}'`
vmsize=`grep VmSize /proc/$vod_pid/status | awk '{print $2}'`

today=`date +%Y%m%d`
year=`date +%Y`
month=`date +%m`
day=`date +%d`
err_log=`grep -c -i err /var/log/castis/vod_log/EventLog[$today].log`
fail_log=`grep -c -i fail /var/log/castis/vod_log/EventLog[$today].log`
nomedia=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'No Media'`
reset=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'Reset'`
session=`cat /var/run/civod/session.count`
process=`ps -eo lstart,comm |grep VOD | head -n 1 | awk '{print $4}'`

echo "`hostname` `date +%F,%T` $cpu_idle $vmpeak $vmsize $err_log $fail_log $nomedia $reset $session $process" >> /home/castis/log/$today.check.log




송파
=========================
남수원

#!/bin/sh

cpu_idle=`vmstat 2 2 | tail -n 1 | awk '{print $15}'`
[ `getconf LONG_BIT` -eq 32 ] && vod_pid=`pidof IPVODServer2`
[ `getconf LONG_BIT` -eq 64 ] && vod_pid=`pidof CiHVODServer`
vmpeak=`grep VmPeak /proc/$vod_pid/status | awk '{print $2}'`
vmsize=`grep VmSize /proc/$vod_pid/status | awk '{print $2}'`

today=`date +%Y%m%d`
year=`date +%Y`
month=`date +%m`
day=`date +%d`
err_log=`grep -c -i err /var/log/castis/vod_log/EventLog[$today].log`
fail_log=`grep -c -i fail /var/log/castis/vod_log/EventLog[$today].log`
nomedia=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'No Media'`
reset=`cat /var/log/castis/vod_log/$year-$month/$year-$month-$day* | grep -c 'Reset'`
session=`cat /var/run/civod/session.count`
process=`ps -eo lstart,comm |grep VOD | head -n 1 | awk '{print $4}'`
df=`df -h | grep data |awk -F ' ' '{ print $5 }'`
mem=`free | grep buffers | awk -F ' ' '{print $4}' | grep -v shared`
buffer=`free | grep Mem | awk -F ' ' '{print $4}' | grep -v shared`
drop1=`tc -d -s qdisc | grep -A1 'eth2' | egrep -v 'qdisc|--' | cut -d , -f1 | cut -d ' ' -f8`
drop2=`tc -d -s qdisc | grep -A1 'eth3' | egrep -v 'qdisc|--' | cut -d , -f1 | cut -d ' ' -f8`
drop3=`tc -d -s qdisc | grep -A1 'eth4' | egrep -v 'qdisc|--' | cut -d , -f1 | cut -d ' ' -f8`
drop4=`tc -d -s qdisc | grep -A1 'eth5' | egrep -v 'qdisc|--' | cut -d , -f1 | cut -d ' ' -f8`

let 'free_mem=mem+buffer'
let 'drop=drop1+drop2+drop3+drop4'

echo "`hostname` `date +%F,%T` CPUIdle:$cpu_idle Memory:$free_mem Storage:$df QDrop:$drop ErrCount:$err_log FailCount:$fail_log NoMedia:$nomedia Reset:$reset SessionCount:$session ProcessTime:$process" >> /home/castis/log/$today.check.log


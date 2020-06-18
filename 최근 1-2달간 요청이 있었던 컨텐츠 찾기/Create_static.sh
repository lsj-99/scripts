#!/bin/bash

#Config
Collection_month=2
tool_path=/usr/local/castis/tools
###############
StaticPath=`cat /usr/local/castis/lfm.cfg | grep Static | cut -d= -f2`
year_month_ago=`date +%Y%m -d '1 month ago'`
year_month=`date +%Y%m`

Dir_Check(){

}

log(){

cur_time=`date +%F,%T`
log_today=`date +%Y%m%d`
echo $cur_time,$1,$2 >> $log_path/$log_today.log

}
then
        log $2 "DownLoad Success"
else
        log $2 "DownLoad Fail"
fi

}
        let j+=1
done

rm -f $result_path/.request 2> /dev/null
rm -f $result_path/.request_all 2> /dev/null
Dir_Check
log Script Start
log "Collection_month=$Collection_month"
for((j=0;i<${#node_ip[@]};++j))
do
        for((i=1;i<=9;i++))
        do
                if [ $Collection_month -eq 2 ]
                then
                        DownCheck $result_path/EventLog_$i EventLog["$year_month_ago"0$i].log
                        rm -f $result_path/EventLog_$i

                        $tool_path/SampleNetIODownloader ${node_ip[$j]} $result_path/EventLog_$i /var/log/castis/vod/EventLog["$year_month"0$i].log 10000000
                        cat $result_path/EventLog_$i | grep Adv | grep Start | cut -d"(" -f2 | cut -d")" -f1 >> $result_path/.request_all
                        DownCheck $result_path/EventLog_$i EventLog["$year_month"0$i].log
                        rm -f $result_path/EventLog_$i
                else
                        $tool_path/SampleNetIODownloader ${node_ip[$j]} $result_path/EventLog_$i /var/log/castis/vod/EventLog["$year_month"0$i].log 10000000
                        cat $result_path/EventLog_$i | grep Adv | grep Start | cut -d"(" -f2 | cut -d")" -f1 >> $result_path/.request_all
                        DownCheck $result_path/EventLog_$i EventLog["$year_month"0$i].log
                        rm -f $result_path/EventLog_$i
                fi
        done

        if [ $Collection_month -eq 2 ]
        then
                last_day=`cal $month_ago $year | tr -s " " "\n" | tail -1`
                for((i=10;i<=$last_day;i++))
                do
                        $tool_path/SampleNetIODownloader ${node_ip[$j]} $result_path/EventLog_$i /var/log/castis/vod/EventLog["$year_month_ago"$i].log 10000000
                        cat $result_path/EventLog_$i | grep Adv | grep Start | cut -d"(" -f2 | cut -d")" -f1 >> $result_path/.request_all
                        DownCheck $result_path/EventLog_$i EventLog["$year_month_ago"$i].log
                        rm -f $result_path/EventLog_$i
                done
        fi

        for((i=10;i<=$today;i++))
        do
                        $tool_path/SampleNetIODownloader ${node_ip[$j]} $result_path/EventLog_$i /var/log/castis/vod/EventLog["$year_month"$i].log 10000000
                        cat $result_path/EventLog_$i | grep Adv | grep Start | cut -d"(" -f2 | cut -d")" -f1 >> $result_path/.request_all
                        DownCheck $result_path/EventLog_$i EventLog["$year_month"$i].log
                        rm -f $result_path/EventLog_$i
        done
done

cat $result_path/.request_all | cut -d"/" -f3 | sort | uniq > $result_path/.request
cp -f $StaticPath $result_path/.static
log Org_static "Copy Success"

rm -f $result_path/static > /dev/null 2> /dev/null
for list in `cat $result_path/.static`
do
        cat $result_path/.request | grep $list >> $result_path/static
done

cp -f $result_path/static $backup_path/static_$year_month
log New_static "Create Success"
log Script Finish
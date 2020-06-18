#!/bin/bash
version=v1.0.0

log_path=/usr/local/tomcat/logs/RecommendEngine
Select_date=$1
dir=`dirname $0`
today=`date +%Y%m%d`

Main(){

echo "$Select_date" >> $dir/$Select_date.result
echo "TIME 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23" >> $dir/$Select_date.result
echo "##################################################################" >> $dir/$Select_date.result
for API in `cat $dir/API_list.txt`
do
        echo "" >> $dir/$Select_date.result
        echo -n $API, >> $dir/$Select_date.result
        for hour in `echo {00..23}`
        do
                count=`cat $log_path/RecommendEngine.log.$Select_date-$hour | grep $API | wc -l`
                echo -n $count, >> $dir/$Select_date.result
        done
done

echo "" >> $dir/$Select_date.result
echo -n total, >> $dir/$Select_date.result

for((i=2;i<=25;i++))
do
        total=`grep -A 100 "#" $dir/$Select_date.result | grep -v "#" | awk -F , -v count=$i '{sum+=$count} END{print sum}'`
        echo -n $total, >> $dir/$Select_date.result
done

echo "" >> $dir/$Select_date.result
}

case $1 in
         [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
                Main
                ;;
        *)
                echo "use xxxx-xx-xx"
                exit
esac
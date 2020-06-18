#!/bin/bash

#####config#####
FMS_LB_ip=192.168.35.151
UHD_LB_ip=192.168.35.160
DMC_LB_Representative_ip=192.168.35.120
DMC_SRM_ip=192.168.35.131 #SRM
LB0=DMC,192.168.35.121
LB1=SGD,192.168.35.200
LB2=GA,192.168.34.210
LB3=SR,192.168.124.130
LB4=KH,192.168.117.130
LB5=BS,192.168.118.130
LB6=CB,192.168.113.40
LB7=KB,192.168.123.130
DMC_ADS_Log_Dir=/var/log/castis/ExClientADS_Log
tool_path=/usr/local/castis/tools
log_dir=/home/castis/Import_Remove_summary/log
info_dir=/home/castis/Import_Remove_summary/info

###############

result_path=`dirname $0`
today=`date +%Y-%m-%d`
date=`date +%Y-%m-%d -d '1 day ago'`

dir_check(){

[ ! -d $log_dir/$year_month ] && mkdir -p $log_dir/$year_month
[ ! -d $result_path/result/$year_month ] && mkdir -p $result_path/result/$year_month
[ ! -d $info_dir/$year_month ] && mkdir -p $info_dir/$year_month

log(){

cur_time=`date +%F,%T`

echo "$cur_time,$1,$2" >> $log_dir/$year_month/$today.log

Check(){

if [ -s $1 ]
then
        log $2 "$3 Fail or No File"
fi

}

Import(){

$result_path/expect.sh $IP "$DMC_ADS_Log_Dir/$year_month/$date* | grep PASSED" | grep -v spawn | grep -v pass | grep -v ATTEMPT > $result_path/result/$year_month/"$today"_ADS_Import
Check $result_path/result/$year_month/"$today"_ADS_Import ADS_Import_Counting
Import_Contents=`cat $result_path/result/$year_month/"$today"_ADS_Import | wc -l`
nomal=`cat $result_path/result/$year_month/"$today"_ADS_Import | grep -v hbz | wc -l`
hbz=`cat $result_path/result/$year_month/"$today"_ADS_Import | grep hbz | wc -l`

echo $today >> $info_dir/$year_month/$today.log
echo "$IP Import_Contents:$Import_Contents(nomal:$nomal hbz=$hbz" >> $info_dir/$year_month/$today.log

}

Remove_list(){

Check $result_path/result/$year_month/"$today"_$1_LB_Remove $1 LB_Remove_Counting
remove=`cat $result_path/result/$year_month/"$today"_$1_LB_Remove | wc -l`

echo "$1 Remove_list(802):$remove" >> $info_dir/$year_month/$today.log

}

use_contents(){

echo "###$1###" >> $info_dir/$year_month/$today.log
Check $result_path/result/$year_month/"$today"_$1_DMC_Request $1 DMC_Request_Counting
DMC_Req=`cat $result_path/result/$year_month/"$today"_$1_DMC_Request | wc -l`

echo "$1 DMC_Request:$DMC_Req" >> $info_dir/$year_month/$today.log

Check $result_path/result/$year_month/"$today"_$1_FMS_Request $1 FMS_Request_Counting
FMS_Req=`cat $result_path/result/$year_month/"$today"_$1_FMS_Request | wc -l`

echo "$1 FMS_Request:$FMS_Req" >> $info_dir/$year_month/$today.log

Check $result_path/result/$year_month/"$today"_$1_UHD_Request $1 UHD_Request_Counting
UHD_Req=`cat $result_path/result/$year_month/"$today"_$1_UHD_Request | wc -l`

echo "$1 UHD_Request:$UHD_Req" >> $info_dir/$year_month/$today.log

ip=$1
node_ip=`echo $1 | cut -d. -f1,2,3`
Check $result_path/result/$year_month/"$today"_$1_SO_Request $1 SO_Request_Counting
SO_Req=`cat $result_path/result/$year_month/"$today"_$1_SO_Request | wc -l`

echo "$1 SO_Request:$SO_Req" >> $info_dir/$year_month/$today.log
let ALL_req=$DMC_Req+$FMS_Req+$UHD_Req+$SO_Req
echo "$1 ALL_Request:$ALL_req" >> $info_dir/$year_month/$today.log

storage_contetns_count=`cat $result_path/result/$year_month/"$today"_$1_hitcount | wc -l`
echo "$1 In_Storage_Contents_Count=$storage_contetns_count" >> $info_dir/$year_month/$today.log
}

storage_contents(){

$tool_path/SampleNetIODownloader $1 $result_path/result/$year_month/$1_lb /usr/local/castis/lb.cfg 1000000
lb_path=`cat $result_path/result/$year_month/$1_lb | grep Hitcount_History_File | cut -d= -f2`

$tool_path/SampleNetIODownloader $1 $result_path/result/$year_month/"$today"_$1_hitcount $lb_path 1000000

}



script_start(){

Import

for list in `cat $script | grep LB | grep -v "_" | grep -v "#" | grep -v "|" | cut -d, -f2`
do
        Remove_list $list
        storage_contents $list
done

DMC_IP=`echo $LB0 | cut -d, -f2`
echo "###$DMC_IP###" >> $info_dir/$year_month/$today.log
DMC_Contents=`cat $result_path/result/$year_month/"$today"_"$DMC_IP"_hitcount | wc -l`
echo "$1 In_Storage_Contents_Count=$DMC_Contents" >> $info_dir/$year_month/$today.log
for list in `cat $script | grep LB | grep -v DMC |grep -v "_" | grep -v "#" | grep -v "|" | cut -d, -f2`
do
        use_contents $list
done

}

ifno_time=`date +%Y%m%d%H%M`

case "$1" in
        start)
                dir_check
                echo "###$info_time###" >> $info_dir/$year_month/$today.log
                script_start
                ;;
        *)
                echo "option start"
esac
exit
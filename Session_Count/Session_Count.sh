#!/bin/bash

number=3
path=/home/castis/session_check
cur_time=`date +%F,%T`
today=`date +%F`

$path/expect.sh 192.168.35.141 data1 | grep -v spawn | grep -v pass > $path/.vod1_data1
vod1_data1_count=`cat $path/.vod1_data1 | awk '$1 >= 3 {print $1,$2}' | wc -l`
vod1_data1_max_count=`cat $path/.vod1_data1 | head -1 | awk '{print $1}'`

$path/expect.sh 192.168.35.141 sdata | grep -v spawn | grep -v pass > $path/.vod1_sdata
vod1_sdata_count=`cat $path/.vod1_sdata | awk '$1 >= 3 {print $1,$2}' | wc -l`
vod1_sdata_max_count=`cat $path/.vod1_sdata | head -1 | awk '{print $1}'`

vod1_bandwidth=`/usr/local/castis/tools/vodcmd all status | awk '{print $3}' | sed -n 1p`

$path/expect.sh 192.168.35.142 data1 | grep -v spawn | grep -v pass > $path/.vod2_data1
vod2_data1_count=`cat $path/.vod2_data1 | awk '$1 >= 3 {print $1,$2}' | wc -l`
vod2_data1_max_count=`cat $path/.vod2_data1 | head -1 | awk '{print $1}'`

$path/expect.sh 192.168.35.142 sdata | grep -v spawn | grep -v pass > $path/.vod2_sdata
vod2_sdata_count=`cat $path/.vod2_sdata | awk '$1 >= 3 {print $1,$2}' | wc -l`
vod2_sdata_max_count=`cat $path/.vod2_sdata | head -1 | awk '{print $1}'`

vod2_bandwidth=`/usr/local/castis/tools/vodcmd all status | awk '{print $3}' | sed -n 2p`

echo "#####" >> $path/$today.log
echo "$cur_time,VOD1 Bandwidth:$vod1_bandwidth,DAS_more_$number"_Count":$vod1_data1_count,DAS_max_Count:$vod1_data1_max_count" >> $path/$today.log
echo "$cur_time,VOD1 Bandwidth:$vod1_bandwidth,SAN_more_$number"_Count":$vod1_sdata_count,SAN_max_Count:$vod1_sdata_max_count" >> $path/$today.log
echo "$cur_time,VOD2 Bandwidth:$vod2_bandwidth,DAS_more_$number"_Count":$vod2_data1_count,DAS_max_Count:$vod2_data1_max_count" >> $path/$today.log
echo "$cur_time,VOD2 Bandwidth:$vod2_bandwidth,SAN_more_$number"_Count":$vod2_sdata_count,SAN_max_Count:$vod2_sdata_max_count" >> $path/$today.log
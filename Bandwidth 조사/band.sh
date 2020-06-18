#!/bin/bash

Repre=`cat /usr/local/castis/lb.cfg | grep "Representative_IP_Address" | cut -d= -f2`
hit_path=`cat /usr/local/castis/lb.cfg | grep "Hitcount_History_File" | cut -d= -f2`
place=CT1
file_path=/home/castis/"$place"

cd $file_path

for((i=25;i<=31;i++))
do

cat /var/log/castis/glb_log/2015-03/2015-03-"$i"* >> $file_path/glb_"$i"_all_log

done

for((i=25;i<=31;i++))
do

cat $file_path/glb_"$i"_all_log | grep "result is success" | grep $Repre >> $file_path/"$i"_local_req

cat $file_path/"$i"_local_req | grep "_K" | cut -d"[" -f5 | cut -d"]" -f1 >> $file_path/local_"$i"_KT
cat $file_path/local_"$i"_KT | sort | uniq -c | sort -nr >> $file_path/local_"$i"_KT_sort
cat $file_path/local_"$i"_KT_sort | awk '{print $2}' >> $file_path/local_"$i"_KT_sort_temp

cat $file_path/"$i"_local_req | grep -v "_K" | cut -d"[" -f5 | cut -d"]" -f1 >> $file_path/local_"$i"_NDS
cat $file_path/local_"$i"_NDS | sort | uniq -c | sort -nr >> $file_path/local_"$i"_NDS_sort
cat $file_path/local_"$i"_NDS_sort | awk '{print $2}' >> $file_path/local_"$i"_NDS_sort_temp

cat $file_path/glb_"$i"_all_log | grep "result is success" | grep -v $Repre >> $file_path/"$i"_center_req

cat $file_path/"$i"_center_req | grep "_K" | cut -d"[" -f5 | cut -d"]" -f1 >> $file_path/center_"$i"_KT
cat $file_path/center_"$i"_KT | sort | uniq -c | sort -nr >> $file_path/center_"$i"_KT_sort
cat $file_path/center_"$i"_KT_sort | awk '{print $2}' >> $file_path/center_"$i"_KT_sort_temp

cat $file_path/"$i"_center_req | grep -v "_K" | cut -d"[" -f5 | cut -d"]" -f1 >> $file_path/center_"$i"_NDS
cat $file_path/center_"$i"_NDS | sort | uniq -c | sort -nr >> $file_path/center_"$i"_NDS_sort
cat $file_path/center_"$i"_NDS_sort | awk '{print $2}' >> $file_path/center_"$i"_NDS_sort_temp

        for list in `cat local_"$i"_KT_sort_temp`
        do
                local_KT_band=`cat hitcount | grep $list | cut -d, -f2`
                if [ -z "$local_KT_band" ]
                then
                        local_KT_band=6300000
                fi
                local_KT_count=`cat local_"$i"_KT_sort | grep $list | awk '{print $1}'`
                temp=`expr $local_KT_band \* $local_KT_count`
                let sum=sum+$temp
        done
                echo $sum >> local_"$i"_KT_band_sum
		sum=0
        for list in `cat local_"$i"_NDS_sort_temp`
        do
                local_NDS_band=`cat hitcount | grep $list | cut -d, -f2`
                if [ -z "$local_NDS_band" ]
                then
                        local_NDS_band=6300000
                fi
                local_NDS_count=`cat local_"$i"_NDS_sort | grep $list | awk '{print $1}'`
                temp=`expr $local_NDS_band \* $local_NDS_count`
                let sum=sum+$temp
        done
                echo $sum >> local_"$i"_NDS_band_sum
		sum=0
        for list in `cat center_"$i"_KT_sort_temp`
        do
                center_KT_band=`cat hitcount | grep $list | cut -d, -f2`
                if [ -z "$center_KT_band" ]
                then
                        center_KT_band=6300000
                fi
                center_KT_count=`cat center_"$i"_KT_sort | grep $list | awk '{print $1}'`
                temp=`expr $center_KT_band \* $center_KT_count`
                let sum=sum+$temp
        done
                echo $sum >> center_"$i"_KT_band_sum
		sum=0
        for list in `cat center_"$i"_NDS_sort_temp`
        do
                center_NDS_band=`cat hitcount | grep $list | cut -d, -f2`
                if [ -z "$center_NDS_band" ]
                then
                        center_NDS_band=6300000
                fi
                center_NDS_count=`cat center_"$i"_NDS_sort | grep $list | awk '{print $1}'`
                temp=`expr $center_NDS_band \* $center_NDS_count`
                let sum=sum+$temp
        done
                echo $sum >> center_"$i"_NDS_band_sum
		sum=0
rm -f $file_path/glb_"$i"_all_log
rm -f $file_path/"$i"_local_req
rm -f $file_path/"$i"_center_req
rm -f $file_path/local_"$i"_KT_sort_temp
rm -f $file_path/local_"$i"_NDS_sort_temp
rm -f $file_path/center_"$i"_KT_sort_temp
rm -f $file_path/center_"$i"_NDS_sort_temp

done
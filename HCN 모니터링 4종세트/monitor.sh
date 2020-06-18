#!/bin/bash

#########################

LB0=DMC,192.168.35.121
LB1=SGD,192.168.35.200
LB2=GA,192.168.34.210
LB3=SR,192.168.124.130
LB4=KH,192.168.117.130
LB5=BS,192.168.118.130
LB6=CB,192.168.113.40
LB7=KB,192.168.123.130
result_path=/home/castis/monitor_bak
tool_path=/usr/local/castis/tools
info_path=/home/castis/monitor_bak/info

##########################
today=`date +%Y%m%d`
year_month=`date +%Y-%m`
path=$0

dir_check(){

[ ! -d $result_path/log/$year_month/NoMedia ] && mkdir -p $result_path/log/$year_month/NoMedia
[ ! -d $result_path/log/$year_month/NoMedia/back ] && mkdir -p $result_path/log/$year_month/NoMedia/back

[ ! -d $result_path/log/$year_month/File_Not_Found ] && mkdir -p $result_path/log/$year_month/File_Not_Found
[ ! -d $result_path/log/$year_month/File_Not_Found/back ] && mkdir -p $result_path/log/$year_month/File_Not_Found/back

[ ! -d $result_path/log/$year_month/vodcmd ] && mkdir -p $result_path/log/$year_month/vodcmd
[ ! -d $result_path/log/$year_month/vodcmd/back ] && mkdir -p $result_path/log/$year_month/vodcmd/back

[ ! -d $result_path/log/$year_month/Adv_File_Not_Found ] && mkdir -p $result_path/log/$year_month/Adv_File_Not_Found
[ ! -d $result_path/log/$year_month/Adv_File_Not_Found/back ] && mkdir -p $result_path/log/$year_month/Adv_File_Not_Found/back

}

log(){

cur_time=`date +%F,%T`
today=`date +%Y%m%d`

echo $cur_time,$1,$2 >> $result_path/log/$year_month/$today.log

info(){

cur_time=`date +%F,%T`
today=`date +%Y%m%d`

echo $cur_time,$1,$2 >> $info_path/$today.info

}

src_down(){

$tool_path/SampleNetIODownloader $1 $result_path/.$1_lb.cfg /usr/local/castis/lb.cfg 10000000

}

NoMedia_Check(){

log $1 "NoMedia Check Start"
for vod_list in `cat $result_path/."$1"_lb.cfg | grep "Address=" | grep -v Default | grep -v IP | cut -d= -f2`
do
        rm -f $result_path/log/$year_month/NoMedia/"$vod_list"_No_Media > /dev/null 2> /dev/null
        if [ $nomedia_check -ge 2 ] 2> /dev/null
        then
                cp $result_path/log/$year_month/NoMedia/."$vod_list"_No_Media $result_path/log/$year_month/NoMedia/"$vod_list"_No_Media
                cp $result_path/log/$year_month/NoMedia/"$vod_list"_No_Media $result_path/log/$year_month/NoMedia/back/"$log_date"_"$vod_list"_No_Media
                log $vod_list "find NoMedia"
                info $vod_list "find NoMedia"
                echo
        fi
done
log $1 "NoMedia Check Finish"

}

for ip in `cat $path | grep LB | grep -v "#" | grep -v "|" | cut -d, -f2`
do
        if [ -s $result_path/log/$year_month/vodcmd/."$ip"_vodcmd ]
        then
                cp $result_path/log/$year_month/vodcmd/."$ip"_vodcmd $result_path/log/$year_month/vodcmd/"$ip"_vodcmd
                cp $result_path/log/$year_month/vodcmd/"$ip"_vodcmd $result_path/log/$year_month/vodcmd/back/"$log_date"_"$ip"_vodcmd
                log $ip "find vodcmd error"
                info $ip "find vodcmd error"
                log `cat $result_path/log/$year_month/vodcmd/."$ip"_vodcmd`
        fi
        log $ip "vod cmd Finish"
done

}

File_Not_Found(){

log $1 "File_Not_Found Start"
date=`date +%Y-%m-%d -d '1 day ago'`
log_date=`date +%Y%m%d%H%m`
rm -f $result_path/log/$year_month/File_Not_Found/$1_File_Not_Found_Result > /dev/null 2> /dev/null
if [ -s $result_path/log/$year_month/File_Not_Found/.$1_File_Not_Found_Result ]
then
        cp $result_path/log/$year_month/File_Not_Found/.$1_File_Not_Found_Result $result_path/log/$year_month/File_Not_Found/$1_File_Not_Found_Result
        log $1 "Find File_Not_Found"
        info $1 "find File_Not_Found"
fi
log $1 "File_Not_Found Finish"

}

Adv_File_Not_Found(){

log $1 "Adv_File_Not_Found Start"
date=`date +%Y%m%d -d '1 day ago'`
log_date=`date +%Y%m%d%H%m`
rm -f $result_path/log/$year_month/Adv_File_Not_Found/"$vod_list"_Adv_File_Not_Found > /dev/null 2> /dev/null
for vod_list in `cat $result_path/."$1"_lb.cfg | grep "Address=" | grep -v Default | grep -v IP | cut -d= -f2`
do
        $result_path/expect.sh $vod_list "cat /var/log/castis/vod/EventLog\[$date* | grep found" | grep -v spawn | grep -v pass | grep -v ATTEMPT | grep -v such > $result_path/log/$year_month/Adv_File_Not_Found/."$vod_list"_Adv_File_Not_Found
        if [ -s $result_path/log/$year_month/Adv_File_Not_Found/."$vod_list"_Adv_File_Not_Found ]
        then
                cp $result_path/log/$year_month/Adv_File_Not_Found/."$vod_list"_Adv_File_Not_Found $result_path/log/$year_month/Adv_File_Not_Found/"$vod_list"_Adv_File_Not_Found
                cp $result_path/log/$year_month/Adv_File_Not_Found/."$vod_list"_Adv_File_Not_Found $result_path/log/$year_month/Adv_File_Not_Found/back/"$vod_list"_Adv_File_Not_Found
                log $vod_list "find Adv_File_Not_Found"
                info $vod_list "find Adv_File_Not_Found"
        fi
done
log $1 "Adv_File_Not_Found Finish"

}

Main(){

for ip in `cat $path | grep LB | grep -v "#" | grep -v "|" | cut -d, -f2`
do
        src_down $ip
        NoMedia_Check $ip
        File_Not_Found $ip
        Adv_File_Not_Found $ip
done

}

start_date=`date +%Y%m%d%H%M`
case "$1" in
        start)
                dir_check
                echo "####$start_date####" >> $info_path/$today.info
                Main
                ;;
        vodcmd)
                dir_check
                echo "####vodcmd####" >> $info_path/$today.info
                vodcmd
                ;;
        *)
                echo "[option start, vodcmd(crontab)]"
esac
exit
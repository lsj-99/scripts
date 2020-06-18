#!/bin/bash
#2015-02-09 LSJ
######config######
File_dir_path=/home/castis/Hitcount_File
Node0=DMC_LB,192.168.25.46
Node1=FMS_LB,192.168.25.234
Node2=ND_LB,172.16.84.51
Node3=DG_LB,172.16.243.100
Node4=ABC_LB,172.16.5.51
DMC_ip=`cat $File_dir_path/Hitcount_File.sh | grep DMC | grep -v "|" | grep -v " " | cut -d, -f2`
FMS_ip=`cat $File_dir_path/Hitcount_File.sh | grep FMS | grep -v "|" | grep -v " " | cut -d, -f2`
Program_path=/usr/local/castis/tools
#################
dir_check(){
today=`date +%Y%m%d`
log_dir=`date +%Y-%m`
[ ! -d $File_dir_path ] && mkdir $File_dir_path > /dev/null 2> /dev/null
[ ! -d $File_dir_path/Src ] && mkdir $File_dir_path/Src > /dev/null 2> /dev/null
[ ! -d $File_dir_path/Src/Backup ] && mkdir $File_dir_path/Src/Backup > /dev/null 2> /dev/null
[ ! -d $File_dir_path/Result ] && mkdir $File_dir_path/Result > /dev/null 2> /dev/null
[ ! -d $File_dir_path/Result/Backup ] && mkdir $File_dir_path/Result/Backup > /dev/null 2> /dev/null
[ ! -d $File_dir_path/log ] && mkdir $File_dir_path/log > /dev/null 2> /dev/null
[ ! -d $File_dir_path/log/$today ] && mkdir $File_dir_path/log/$log_dir > /dev/null 2> /dev/null
mv $File_dir_path/Src/* $File_dir_path/Src/Backup > /dev/null 2> /dev/null
mv $File_dir_path/Result/* $File_dir_path/Result/Backup > /dev/null 2> /dev/null
}

log(){

today=`date +%Y%m%d`
cur_time=`date +%F,%T`
log_dir=`date +%Y-%m`

cat $File_dir_path/Src/$1"_"$3 | grep success
if [ $? == 0 ]
then
        echo $cur_time,$1,$2,Download success >> $File_dir_path/log/$log_dir/$today.log
else
        echo $cur_time,$1,$2,Download Fail >> $File_dir_path/log/$log_dir/$today.log

fi

}

src_download(){

today=`date +%Y%m%d`
cd $File_dir_path/Src
SrcDownloadWaitTimeInMil=3000

$Program_path/SampleNetIODownloader_New $1 $File_dir_path/Src/$today"_"$1"_lb.cfg" /usr/local/castis/lb.cfg 10000000 > /dev/null 2> $File_dir_path/Src/$1"_lb_result"
usleep `expr $SrcDownloadWaitTimeInMil \* 1000`
log $1 "lb.cfg" "lb_result"
lb_path=`cat $today"_"$1"_lb.cfg" | grep Hitcount_History_File | cut -d'=' -f 2`

dos2unix $today"_"$1"_lb.cfg"
$Program_path/SampleNetIODownloader_New $1 $File_dir_path/Src/$today"_"$1"_hitcount" $lb_path 10000000 > /dev/null 2> $File_dir_path/Src/$1"_hitcount_result"
usleep `expr $SrcDownloadWaitTimeInMil \* 1000`
log $1 "hitcount" "hitcount_result"

cat $File_dir_path/Src/$today"_"$1"_hitcount" | egrep '^M0' | cut -d',' -f1 >> $File_dir_path/Src/$today"_"$1"_all_file"
all_file_count=`cat $File_dir_path/Src/$today"_"$1"_hitcount" | wc -l`
all_file_size=`cat $File_dir_path/Src/$today"_"$1"_hitcount" | cut -d',' -f4 | awk '{ sum += $1 } END { print (sum/1024/1024/1024)" GB" }'`
echo $1",File_Count:"$all_file_count",File_Size:"$all_file_size >> $File_dir_path/Result/$today"_"$1"_Result"

rm -rf $today"_"$1"_lb.cfg"
rm -rf $1_"lb_result"
rm -rf $1"_hitcount_result"
}

src_compare(){
today=`date +%Y%m%d`
cur_time=`date +%F,%T`
log_dir=`date +%Y-%m`
cd $File_dir_path/Src
for list in `cat $today"_"$1"_all_file"`
do
        cat $today"_"$DMC_ip"_all_file" | grep -w $list > /dev/null 2> /dev/null
        if [ $? == 1 ]
        then
                echo $list >> $File_dir_path/Result/$today"_"$1"_DMC_SO_Only"
        fi
done
echo $cur_time,$1"_DMC_SO_Only_success" >> $File_dir_path/log/$log_dir/$today.log
}
src_compare2(){
today=`date +%Y%m%d`
cur_time=`date +%F,%T`
log_dir=`date +%Y-%m`
cd $File_dir_path/Src
for list in `cat $File_dir_path/Result/$today"_"$1"_DMC_SO_Only"`
do
        cat $today"_"$FMS_ip"_all_file" | grep -w $list > /dev/null 2> /dev/null
        if [ $? == 1 ]
        then
                echo $list >> $File_dir_path/Result/$today"_"$1"_FMS_SO_Only"
        fi
done
echo $cur_time,$1"_FMS_SO_Only_Compare_success" >> $File_dir_path/log/$log_dir/$today.log

}

src_compare3(){

today=`date +%Y%m%d`
cur_time=`date +%F,%T`
log_dir=`date +%Y-%m`
cd $File_dir_path/Result

for list in `cat $today"_"$1"_DMC_SO_Only"`
do
        cat $today"_"$1"_FMS_SO_Only" | grep -w $list > /dev/null 2> /dev/null
        if [ $? == 1 ]
        then
                echo $list >> $File_dir_path/Result/$today"_"$1"_FMS_SO_Both"
                File_size=`cat $File_dir_path/Src/$today"_"$1"_hitcount" | grep $list | cut -d, -f4`
                let sum=sum+$File_size
        fi
        done
        let total=sum/1024/1024/1024
Can_remove_files=`cat $File_dir_path/Result/$today"_"$1"_FMS_SO_Both" | wc -l`

echo $1",Can_remove_File_Count:"$Can_remove_files",Can_remove_File_Size:"$total "GB" >> $File_dir_path/Result/$today"_"$1"_Result"
echo $cur_time,$1"_FMS_SO_Both_Compare_success" >> $File_dir_path/log/$log_dir/$today.log

}

start_ps(){

DownloadWaitTimeInMil=10000
CompareWaitTimeInMil=600000

for download in `cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | cut -d, -f2`
do
        src_download $download &
done

usleep `expr $DownloadWaitTimeInMil \* 1000`

for DMC_SO_Only in `cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | grep -v $DMC_ip | grep -v $FMS_ip | cut -d, -f2`
do
        src_compare $DMC_SO_Only &
done

usleep `expr $CompareWaitTimeInMil \* 1000`

for FMS_SO_Only in `cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | grep -v $DMC_ip | grep -v $FMS_ip | cut -d, -f2`
do
        src_compare2 $FMS_SO_Only &
done

usleep `expr $CompareWaitTimeInMil \* 1000`

for FMS_SO_Both in `cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | grep -v $DMC_ip | grep -v $FMS_ip | cut -d, -f2`
do
        src_compare3 $FMS_SO_Both &
done

}

search(){

today=`date +%Y%m%d`

for summary in `cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | cut -d, -f2`
do
        echo "######################"
        cat $File_dir_path/Result/$today"_"$summary"_Result"
done

}

remove(){

today=`date +%Y%m%d`
cur_time=`date +%F,%T`
log_dir=`date +%Y-%m`
ip=`cat $File_dir_path/Hitcount_File.sh | grep Node | grep -v "|" | grep -v "#" | cut -d, -f2`

cd $File_dir_path/Result

	for remove_file in `cat $1"_FMS_SO_Both"`
	do
		if [ $1 == $DMC_ip ]
		then
			echo $1" is DMC ip Can't Remove"
                elif [ $1 == $FMS_ip ]
		then
			echo $1" is FMS ip Can't Remove"
		else
		$Program_path/LBFileDel $1 $remove_file
		echo $cur_time,$1,$remove_file Remove Request >> $File_dir_path/log/$log_dir/$today"_"$1"_Remove_list.log"
	fi
	done

}

                case "$1" in
                start)
                        dir_check
                        start_ps
                        ;;
                search)
                        search
                        ;;
                remove)
                        remove $2
                        ;;
                *)
                echo "Hitcount_File.sh [option start, search, remove local_lb_ip]"
                esac
                exit

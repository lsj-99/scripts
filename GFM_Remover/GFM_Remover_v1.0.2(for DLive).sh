#!/bin/bash

#####Config#####

node_name=SongPa
Limit_Size_In_GB=14238
NewContentLeafStoreDays=5
Max_Remove_Count=400
Tool_Path=/usr/local/castis/tools
ToDoPathFromToDoFileThread=/var/log/castis/GFM_Remover/Transaction/ToDo
ToDoPath=/var/log/castis/GFM_Remover/Transaction/ToDo
ToDo_Backup=/var/log/castis/GFM_Remover/Transaction/Backup
NewContentsPath=/var/log/castis/GFM_Remover/Transaction/NewContents
StaticPath=/var/log/castis/GFM_Remover/Transaction/Static
SuccessPath=/var/log/castis/GFM_Remover/Transaction/Success
ErrorPath=/var/log/castis/GFM_Remover/Transaction/Error
GFMInfoPath=/var/log/castis/GFM_Remover/Transaction/GFMInfo
Log_Dir=/var/log/castis/GFM_Remover/log

################

version=GFM_Remover_v1.0.3
hit_path=`cat /usr/local/castis/lb.cfg | grep Hitcount_History_File | cut -d= -f2`
local_ip=`cat /usr/local/castis/lb.cfg | grep Representative | cut -d= -f2`
gradeinfo_path=`cat /usr/local/castis/lfm.cfg | grep Grade_Info_File | cut -d= -f2`
static_Path=`cat /usr/local/castis/lfm.cfg | grep Static_File_List | cut -d= -f2`
month=`date +%Y-%m`
today=`date +%Y%m%d`

Dir_Check(){

[ ! -d $ToDoPathFromToDoFileThread ] && mkdir -p $ToDoPathFromToDoFileThread
[ ! -d $ToDo_Backup ] && mkdir -p $ToDo_Backup
[ ! -d $NewContentsPath ] && mkdir -p $NewContentsPath
[ ! -d $StaticPath ] && mkdir -p $StaticPath
[ ! -d $SuccessPath ] && mkdir -p $SuccessPath
[ ! -d $ErrorPath ] && mkdir -p $ErrorPath
[ ! -d $GFMInfoPath ] && mkdir -p $GFMInfoPath
[ ! -d $Log_Dir/$month ] && mkdir -p $Log_Dir/$month

}

log(){

cur_time=`date +%F,%T`
log_today=`date +%F`

echo $version,$cur_time,$1,$2 >> $Log_Dir/$month/$log_today.log

}

Check(){

cat $1 | grep $2 | tail -2 | grep -i fail > /dev/null 2> /dev/null
        if [ $? -eq 0 ]
        then
                log $node_name "$2 Remove Fail!!"
        else
                log $node_name "$2 Remove Success!!"
        fi

}

Backup(){

Backup_date=`date +%Y%m%d_%H`
if [ "$3" = cp ]
then
        cp -f $1 "$2_$Backup_date" > /dev/null 2> /dev/null
else
        mv -f $1 "$2_$Backup_date" > /dev/null 2> /dev/null
fi

}

Copy_Src(){

cp -f $2 $3 > /dev/null 2> /dev/null
log $node_name "$1 Copy Success"

}

Main(){

log $node_name "GFM_Remover start"
NewContents_date=`date +%s -d "$NewContentLeafStoreDays day ago"`
#Src_Download
Copy_Src "static_File_List" $static_Path $ToDoPathFromToDoFileThread/.static_File_List
Copy_Src "Hitcount" $hit_path $ToDoPathFromToDoFileThread/.Hitcount
Copy_Src "gradeInfo" $gradeinfo_path $ToDoPathFromToDoFileThread/.gradeInfo
cat $ToDoPathFromToDoFileThread/.Hitcount | grep -v header | cut -d, -f1,2,4 > $ToDoPathFromToDoFileThread/.Hitcount_cut
cat -n $ToDoPathFromToDoFileThread/.gradeInfo | grep -v file | awk '{print $1,$2}' > $ToDoPathFromToDoFileThread/.grade_n
cat $ToDoPathFromToDoFileThread/.gradeInfo | grep -v file | awk '{print $1}' > $ToDoPathFromToDoFileThread/.grade_cut

#Hit Remake
rm -f $ToDoPathFromToDoFileThread/Hit_Remake > /dev/null 2> /dev/null
rm -f $NewContentsPath/New_Contents > /dev/null 2> /dev/null
log $node_name "Hit Remake start"
for list in `cat $ToDoPathFromToDoFileThread/.grade_cut`
do
        grade=`cat $ToDoPathFromToDoFileThread/.grade_n | grep $list | head -1 | awk '{print $1}'`
        modi=`cat $ToDoPathFromToDoFileThread/.Hitcount_cut | grep ^$list, | cut -d, -f2`
        size=`cat $ToDoPathFromToDoFileThread/.Hitcount_cut | grep ^$list, | cut -d, -f3`
	echo $list,$size >> $ToDoPathFromToDoFileThread/.all_list_temp
        if [ $modi -gt $NewContents_date ] 2> /dev/null
        then
                echo $list,$modi,$size >> $NewContentsPath/New_Contents
        else
                echo $grade,$list,$modi,$size >> $ToDoPathFromToDoFileThread/Hit_Remake
        fi
done
sed -i 's/^/1,/' $NewContentsPath/New_Contents
log $node_name "Hit Remake Finish"

#exclude static
rm -f $StaticPath/STATIC > /dev/null 2> /dev/null
log $node_name "exclude static start"
for list in `cat $ToDoPathFromToDoFileThread/.static_File_List`
do
        cat $ToDoPathFromToDoFileThread/Hit_Remake | grep $list | cut -d, -f2,3,4 >> $StaticPath/STATIC
        sed -i "/$list/d" $ToDoPathFromToDoFileThread/Hit_Remake
done

sed -i 's/^/1,/' $StaticPath/STATIC
Backup "$StaticPath/STATIC" "$ToDo_Backup/STATIC" "cp"
log $node_name "exclude static Finish"

#File Sum
cat $NewContentsPath/New_Contents $StaticPath/STATIC $ToDoPathFromToDoFileThread/Hit_Remake | cut -d, -f1,2,4 > $ToDoPathFromToDoFileThread/ALL_LIST
Backup "$ToDoPathFromToDoFileThread/ALL_LIST" "$ToDo_Backup/ALL_LIST" "cp"
cat $NewContentsPath/New_Contents $StaticPath/STATIC $ToDoPathFromToDoFileThread/Hit_Remake | cut -d, -f2 > $ToDoPathFromToDoFileThread/.ALL_LIST_mpg

#Size Sum
log $node_name "Create Remove List Start"
let max=$Limit_Size_In_GB*1024*1024*1024
sum=0
total=0
for list in `cat $ToDoPathFromToDoFileThread/.ALL_LIST_mpg`
do
       size=`cat $ToDoPathFromToDoFileThread/ALL_LIST | grep $list | cut -d, -f3`
       let sum=sum+$size 2> /dev/null
       if [ $sum -gt $max ]
       then
                last_mpg="$list"
                let sum=sum-$size
                break
       elif [ $sum -lt $max ]
       then
                continue
       else
               break
       fi
done

#Create Remove List
grep -A 99999 "$last_mpg" $ToDoPathFromToDoFileThread/ALL_LIST | grep -v "$last_mpg" > $ToDoPathFromToDoFileThread/.remove_list_temp
cat $ToDoPathFromToDoFileThread/.remove_list_temp | sort -nr | cut -d, -f2 > $ToDoPathFromToDoFileThread/remove_list
Backup "$ToDoPathFromToDoFileThread/.remove_list_temp" "$ToDo_Backup/remove_list_ALL" "cp"
Backup "$ToDoPathFromToDoFileThread/remove_list" "$ToDo_Backup/remove_list" "cp"

#GFM_Info
log $node_name "GFMInfo Craete Start"
Node_Contents_Count=`cat $ToDoPath/.Hitcount_cut | grep -v file | wc -l`
Node_Contetns_Size=`cat $ToDoPath/.Hitcount_cut | cut -d, -f3 | awk '{sum+=$1} END{print sum/1024/1024/1024" GB"}'`
grade_Contents_Size=`cat $ToDoPath/.all_list_temp | awk -F, '{sum+=$2} END{print sum/1024/1024/1024" GB"}'`
Can_Remove_File_Count=`cat $ToDoPath/.remove_list_temp | wc -l`
Can_Remove_File_Size=`cat $ToDoPath/.remove_list_temp | cut -d, -f3 | awk '{remove_sum+=$1} END{print remove_sum/1024/1024/1024" GB"}'`
if [ -z "$Can_Remove_File_Size" ]
then
	Can_Remove_File_Size=0
fi

log_date=`date +%F,%T`

echo >> $GFMInfoPath/Info_$today
echo "#####$log_date#####"  >> $GFMInfoPath/Info_$today
echo "Node_Contents_Count:$Node_Contents_Count" >> $GFMInfoPath/Info_$today
echo "Node_Contetns_Size:$Node_Contetns_Size" >> $GFMInfoPath/Info_$today
echo "grade_Contents_Size=$grade_Contents_Size" >> $GFMInfoPath/Info_$today
echo "Can_Remove_File_Count:$Can_Remove_File_Count" >> $GFMInfoPath/Info_$today
echo "Can_Remove_File_Size:$Can_Remove_File_Size" >> $GFMInfoPath/Info_$today


log $node_name "Can_Remove_File_Count:$Can_Remove_File_Count Can_Remove_File_Size=$Can_Remove_File_Size"

log $node_name "Create Remove List Finish"

}

Remove(){

log $node_name "Remove Start"
#Remove_list_Check
if [ ! -s $ToDoPathFromToDoFileThread/remove_list ]
then
        log $node_name "There are no remove_list. So Finish Remove"
        return
fi

#Remove
rm -f $ToDoPath/Processing_File_Remove > /dev/null 2> /dev/null
for list in `cat $ToDoPath/remove_list | cut -d, -f1 | head -$Max_Remove_Count`
do
        $Tool_Path/LBFileDel/LBFileDel $local_ip $list >> $ToDoPath/Processing_File_Remove
        Check "$ToDoPath/Processing_File_Remove" $list
done
log $node_name "Remove Finish"

#GFM_Info
log $node_name "GFMInfo Craete Start"
Remove_Success_Count=`cat $ToDoPath/Processing_File_Remove | grep success | wc -l` 2> /dev/null
Remove_Fail_Count=`cat $ToDoPath/Processing_File_Remove | grep fail | wc -l` 2> /dev/null

echo "Remove_Success_Count:$Remove_Success_Count" >> $GFMInfoPath/Info_$today
echo "Remove_Fail_Count:$Remove_Fail_Count" >> $GFMInfoPath/Info_$today

cat $ToDoPath/Processing_File_Remove | grep Fail > /dev/null 2> /dev/null
if [ $? -eq 1 ]
then
        Backup "$ToDoPath/Processing_File_Remove" "$SuccessPath/Success" "mv"
        log $node_name "Remove Result is Success. So move to $SuccessPath"
else
        Backup "$ToDoPath/Processing_File_Remove" "$ErrorPath/Error" "mv"
        log $node_name "Remove Result is Fail. So move to $ErrorPath"
fi

log $node_name "GFMInfo Craete Finish"

}

case $1 in
        all)
                Dir_Check
                Main
                Remove
                log $node_name "GFM_Remover Finish"
                ;;
        start)
                Dir_Check
                Main
                log $node_name "GFM_Remover Finish"
                ;;
        remove)
                Remove
                ;;
        *) echo "option [ all(start+remove), start, remove ]"
esac
exit
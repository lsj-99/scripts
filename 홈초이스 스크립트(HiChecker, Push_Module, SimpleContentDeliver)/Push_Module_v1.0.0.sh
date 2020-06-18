#!/bin/bash

#####Config#####

Frozen_ip=172.16.13.12
Frozen_path=/home/castis/Push_test
Watch_Dir=/gfmtmp
Check_Time_In_Sec=5
Copy_Bitrate=100000000
Log_Dir=/var/log/castis/Push
Max_Count=1
Tool_Path=/usr/local/castis/tools

#Link File Delete Option
Link_File_Delte=1
Link_File_Path=/data1

#Move To Error Directory Option
Move_To_Error_Directroy=1
Move_To_Error_Path=/gfmtmp/error

################

version=PushModule_v1.0.0

Log(){

cur_time=`date +%F,%T`
year=`date +%Y`
month=`date +%m`
today=`date +%Y-%m-%d`
[ ! -d $Log_Dir/"$year-$month" ] && mkdir -p $Log_Dir/"$year-$month"

echo $version,$cur_time,$1,$2$3 >> $Log_Dir/"$year-$month"/$today.log

}

NetIO_Check(){

process_ip=`pidof SampleNetIOUploader`
kill $process_ip > /dev/null 2> /dev/null
if [ $? -eq 0 ]
then
        Log Information "find SampleNetIO." ",Kill NetIO Process"
else
        continue
fi

}

Error_Dir(){

if [ $1 -eq 0 ]
then
        [ ! -d $Move_To_Error_Path ] && mkdir $Move_To_Error_Path
        mv -f $3 $Move_To_Error_Path
        Log Fail "Move_To_Error_Directroy=$Move_To_Error_Directroy" ",$2 Copy Fail. Move to $Move_To_Error_Path"
else
        Log Fail "Move_To_Error_Directroy=$Move_To_Error_Directroy" ",$2 Copy Fail. Retry Copy"
fi

}

Link_File_Delete_Check(){

if [ $1 -eq 0 ]
then
        rm -f  $Link_File_Path/$2
        Log Information "Link_File_Delte=$1" ",Remove $Link_File_Path/$2"
else
        return
fi

}

NetIO_Check > /dev/null 2> /dev/null
Log Information PushModule " Start"
while true
do
        sleep $Check_Time_In_Sec
        Check=`ls $Watch_Dir | grep .mpg | wc -l`
        if [ $Check -ge $Max_Count ]
        then
                ls $Watch_Dir | grep .mpg > $Watch_Dir/.remote_move_list
                for list in `cat $Watch_Dir/.remote_move_list`
                do
                        Log Information $Watch_Dir/$list " find"
                        Log Information $Watch_Dir/$list " -> $Frozen_ip:$Frozen_path Copy Start"
                        $Tool_Path/SampleNetIOUploader $Frozen_ip $Watch_Dir/$list $Frozen_path/$list $Copy_Bitrate 2> $Watch_Dir/.copy_result
                        cat $Watch_Dir/.copy_result | grep -i fail > /dev/null 2> /dev/null
                        if [ $? -eq 0 ]
                        then
                                Error_Dir $Move_To_Error_Directroy $list $Watch_Dir/$list
                        else
                                rm -f $Watch_Dir/$list 2> /dev/null
                                Link_File_Delete_Check $Link_File_Delte $list
                                Log Success $list " Copy Success. Delete $Watch_Dir/$list"
                        fi
                done
        else
                continue
        fi
done
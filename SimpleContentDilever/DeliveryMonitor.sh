#!/bin/sh

. dm.cfg
. /usr/local/castis/dm.cfg

function check_rep_ip {

        ifconfig | grep -q $1

        if [ $? -eq 0 ];then
                return 0
        else
                return 1
        fi
}

function check_process_running {

        # $1 example
        # $1 : /usr/local/castis/Script.sh

        # return value
        # 0 : running  ,  1 : not running
        Process_Name=`basename $1`
        Process_Path=`dirname $1`


        Process_Count=`ps ax | grep -w $1 | grep -v grep -c`

        if [ $Process_Count -eq 0 ];then
                echo "$Process_Name not running"
                killall -9 $Process_Name 2> /dev/null
                sleep 1
                return 1
        fi

        return 0

}

function run {

        # $1 example
        # $1 : /usr/local/castis/Script.sh
        Process_Name=`basename $1`
        Process_Path=`dirname $1`

        cd $Process_Path
        $1 >/dev/null 2>/dev/null &
        echo "$Process_Name start"
}

element_count=${#Process[@]}

while true
do
        i=0
        while [ $i -lt $element_count ]
        do
                check_rep_ip ${IP[$i]}

                # not exist rep ip
                if [ $? -eq 1 ]
                then
                        # kill process
                        killall -9 `basename ${Process[$i]}` >/dev/null 2>/dev/null
                        #echo "killall `basename ${Process[$i]}`"

                        # next process
                        ((i++))
                        continue
                fi

                check_process_running ${Process[$i]}

                # process not running
                if [ $? -eq 1 ]
                then
                        # start process
                        run ${Process[$i]}
                fi

                ((i++))
        done

        sleep 3
done
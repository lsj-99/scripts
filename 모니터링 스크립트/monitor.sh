#!/bin/bash
#LSJ

########
#Config#
########
PROGRAM_PATH=/usr/local/castis
VIP=172.16.21.110
MAIN=N_ADSSSS
PS1=ADSControllerrrr
PS2=LFMSinkModuleeee
PS3=LFMClientttt
CheckTimeInMil=5000
RunDelayTimeInMil=500
log_path=/var/log/castis/monitor_log/


#################################Don't Touch#################################


check_ps(){

	ps ax | grep -w $1 | grep -v "grep" > /dev/null 2> /dev/null

}

start_ps(){

	usleep `expr $RunDelayTimeInMil \* 1000`
	$PROGRAM_PATH/$1 > /dev/null 2> /dev/null &

}

stop_ps(){

PS_ID=`pidof -x $1`
	kill -9 $PS_ID > /dev/null 2> /dev/null

}

loggin(){
	
	log_dir=`date +%Y-%m`
	today=`date +%Y%m%d`
	cur_time=`date +%F,%T`
	echo "$cur_time, $1, $2" >> $log_path/$log_dir/$today.log
	
}

no_vip(){
		today=`date +%Y%m%d`
		cur_time=`date +%F,%T`
	    ps ax | grep -w $1 | grep -v "grep" > /dev/null 2> /dev/null
		if [ $? -eq 0 ]
		then
			kill -9 `pidof -x $1` > /dev/null 2> /dev/null
			echo "$cur_time, $VIP, VIP doesn't exist (Kill $1)" >> $log_path/$today.log
		fi
}

[ ! -d $log_path ] && mkdir $log_path

while true
do

	ifconfig | grep -w $VIP > /dev/null 2> /dev/null
	if [ $? -eq 0 ] #VIP exist
	then
		check_ps $MAIN
		if [ $? -eq 0 ] #main alive
		then
			check_ps $PS1
			if [ $? -eq 0 ] #PS1 alive
			then
				check_ps $PS2
				if [ $? -eq 0 ] #PS2 alive
				then
					check_ps $PS3
					if [ $? -eq 0 ] #PS3 alive
					then
						usleep `expr $CheckTimeInMil \* 1000`
						continue
					else #PS3 dead
						start_ps $PS3
						loggin "$PS3 Restart (Start $PS3)"
					fi
				else #PS2 dead
			
					stop_ps $PS3
					start_ps $PS2
					start_ps $PS3
					loggin "$PS2 Restart (Kill $PS3 -> Start $PS2, $PS3)"
				fi
			else #PS1 dead
				stop_ps $PS2
				stop_ps $PS3
				start_ps $PS1 
				start_ps $PS2
				start_ps $PS3
				loggin "$PS1 Restart (Kill $PS2, $PS3 -> Start $PS1, $PS2, $PS3)"
			fi
	    else #N_ADS dead
			loggin "$MAIN Down (Kill $PS1, $PS2, $PS3)"
			usleep `expr $CheckTimeInMil \* 1000`
		    continue
	    fi	
	else #VIP doesn't exist
		no_vip $PS1
		no_vip $PS2
		no_vip $PS3
		usleep `expr $CheckTimeInMil \* 1000`
		continue		
	fi
usleep `expr $CheckTimeInMil \* 1000`
done

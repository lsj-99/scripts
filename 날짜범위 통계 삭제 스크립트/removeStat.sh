#!/bin/bash

function usages(){

echo '+----------------Usages----------------+'
echo '|./removeStat.sh startdate enddate     |'
echo '|ex) ./removeStat.sh 20191010          |'
echo '|ex) ./removeStat.sh 20191010 20191101 |'
echo '+--------------------------------------+'

}

function checkInputDateValidate(){

if [[ $1 =~ ^20[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1])$ ]]
then
	return 0
else
	usages
	exit
fi

}

function checkDateValidate(){

if [ $1 -ge $2 ]
then
	usages
	exit
fi

}

main(){

startDate=$1
endDate=$2
totalCount=0
class=com.bom.freesia.cframework.norm.custom.KBStockOperStatRemover

checkInputDateValidate $1
[ -z $2 ] || checkInputDateValidate $2
[ ! -z $2 ] && checkDateValidate $1 $2

if [ -z ${endDate} ]
then
	echo "#############${startDate}#############"
	/home/freesia/apps/java/bin/java -cp /home/freesia/lib/bom-freesia-1.0-jar-with-dependencies.jar ${class} -zk PLLOGSA-AN01:11500 -d ${startDate}
else
	while true
	do
		targetDate=`date +%Y%m%d -d "${startDate} +${totalCount}days"`
		if [ ${targetDate} -le ${endDate} ]
		then
			echo "#############${targetDate}#############"
			/home/freesia/apps/java/bin/java -cp /home/freesia/lib/bom-freesia-1.0-jar-with-dependencies.jar ${class} -zk PLLOGSA-AN01:11500 -d ${targetDate}
			let totalCount+=1
		else
			echo "total:${totalCount}"
			break
		fi
	done
fi

}

main $1 $2

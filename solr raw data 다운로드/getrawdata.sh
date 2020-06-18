#!/bin/bash

SERVERIP=127.0.0.1
SOLRPORT=11600
DEMONPORT=7777
APPID=w

usages(){

echo '----------------usage----------------'
echo './getrawdata.sh startdate enddate'
echo 'ex) ./getrawdate.sh 20191010'
echo 'ex) ./getrawdate.sh 20191010 20191101'

}

checkInputDateValidate(){

if [[ $1 =~ ^20[0-9]{2}(0[1-9]|1[0-2])(0[0-9]|1[0-9]|3[0-1])$ ]]
then
	return 0
else
	usages
	exit
fi

}

checkDateValidate(){

if [ $1 -gt $2 ]
then
	usages
	exit
fi

}

stopDemon(){

for pid in `ps ax | grep 'bom-exlsy-0.5-SNAPSHOT-jar-with-dependencies.jar' | grep -v grep | awk '{print $1}'`
do
	sudo kill -9 ${pid} 2> /dev/null
done

}

main(){

startDate=$1
endDate=$2
totalCount=0

checkInputDateValidate $1
[ -z $2 ] || checkInputDateValidate $2
[ ! -z $2 ] && checkDateValidate $1 $2

stopDemon
java -cp ./:./bom-exlsy-0.5-SNAPSHOT-jar-with-dependencies.jar com.bom.exlsy.crypto.http.AESHttpServer ${SERVERIP} ${DEMONPORT} & > /dev/null
sleep 5
DEMONPID=$!

if [ -z ${endDate} ]
then
	echo ${startDate}
	curl -s "http://${SERVERIP}:${SOLRPORT}/solr/"${startDate}"/select?q=appid:${APPID}&sort=time%20asc&rows=99999999" | jq -r .response.docs[].orgdata > ${startDate}.rawdata
	rm -rf ${startDate}.data 2> /dev/null
        for dataDec in `cat ${startDate}.rawdata`
        do
		curl -s http://${SERVERIP}:${DEMONPORT}/dec -d "${dataDec/__@ENC@__/}" >> ${startDate}.data
		echo >> ${startDate}.data
	done
else
	while true
	do
		echo `date +%Y%m%d -d "${startDate} +${totalCount}days"`
		targetDate=`date +%Y%m%d -d "${startDate} +${totalCount}days"`
		let totalCount+=1

		curl -s "http://${SERVERIP}:${SOLRPORT}/solr/"${targetDate}"/select?q=appid:${APPID}&sort=time%20asc&rows=99999999" | jq -r .response.docs[].orgdata > ${startDate}.rawdata
		rm -rf ${startDate}.data 2> /dev/null
		for dataDec in `cat ${startDate}.rawdata`
		do
			curl -s http://${SERVERIP}:${DEMONPORT}/dec -d "${dataDec/__@ENC@__/}" >> ${startDate}.data
			echo >> ${startDate}.data
		done
	
		if [ ${targetDate} = ${endDate} ]
		then
			echo "total:${totalCount}"
			break
		fi
	done
fi

sudo kill -9 ${DEMONPID} & > /dev/null 2> /dev/null

}

main $1 $2

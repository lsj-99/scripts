#!/bin/bash

#coponents options
solrBackupOnOff=on
solrBackupDir=/backup_data/se

nosqlBackupOnOff=on
nosqlBackupDir=/backup_data/nosql

zookeeperBackupOnOff=on
zookeeperSourceDir=/data/backup_data/zk
zookeeperBackupDir=/backup_data/zk

mariadbBackupOnOff=on
mariadbSourceDir=/data/backup_data/db
mariadbBackupDir=/backup_data/db

#log option
logDir=/backup_data/log

#load common functions and properties
source /home/freesia/scripts/fudf.sh
source /home/freesia/scripts/FreesiaSysEnv.sh
loadProperties "${FREESIA_PROPS_FILE}"
nodeID="${PROPS[node.id]}"
nodeIP="${PROPS[host.ip]}"
activePort=`${CMD_FADMCTL} se --list | grep ${nodeID} | grep ${nodeIP} | grep active | awk '{print $9}' | head -1`
collectionListAPI="http://${nodeIP}:${activePort}/solr/admin/collections?action=LIST&wt=json"
todayDate=`date +%Y%m%d`
collectionList=`curl -s "${collectionListAPI}" | jq -r '.collections[]' | egrep ^[0-9][0-9] | grep -v ${todayDate} | sort -n`

function logWrite(){
	local logDate=`date +%F`
	local logTime=`date +%F" "%T.%3N`
	local logLevel=$1
	local logBody=$2

	[ ! -d ${logDir} ] && mkdir -p ${logDir}

	echo "${logTime},${logLevel},${logBody}" >> ${logDir}/fbackup_${logDate}.log
}

function solrBackup(){
	[ ! -d ${solrBackupDir} ] && mkdir -p ${solrBackupDir}

	for list in `echo $collectionList`
	do
		#monthly collection delete
		if [[ ${list} =~ ^20[0-9]{2}(0[1-9]|1[0-2])$ ]]
		then
			logWrite INFO "monthly collection : ${list} deleted"
			rm -rf ${solrBackupDir}/${list} 2> /dev/null
		fi

		if [ ! -d ${solrBackupDir}/${list} ]
		then
			curl "http://${nodeIP}:${activePort}/solr/admin/collections?action=BACKUP&name=${list}&collection=${list}&location=${solrBackupDir}"
			if [ -s ${solrBackupDir}/${list}/backup.properties ]
			then
				logWrite INFO "${list} collection Backup Success"
			else
				logWrite FAIL "${list} collection Backup Fail. remove ${solrBackupDir}/${list}"
				rm -rf ${solrBackupDir}/${list}
			fi
		else
			logWrite INFO "${solrBackupDir}/${list} is already exists. so skip backup"
		fi
	done
}

function nosqlBackup(){
	local backupDate=`date +%Y%m%d`
	local nosqlPort=`cat /etc/aerospike/aerospike.conf | grep '                port' | head -1 | awk '{print $2}'`

	[ ! -d ${nosqlBackupDir} ] && mkdir -p ${nosqlBackupDir}

	if [ ! -d ${nosqlBackupDir}/${backupDate} ]
	then
		asbackup -h 127.0.0.1 -p ${nosqlPort} -n freesia -d ${nosqlBackupDir}/${backupDate}
		logWrite INFO "${nosqlBackupDir}/${backupDate} Backup Success"
	else
		logWrite INFO "${nosqlBackupDir}/${backupDate} is already exists. so skip backup"
	fi
}

function zookeeperBackup(){
	local backupDate=`date +%Y%m%d -d '1 day ago'`

	[ ! -d ${zookeeperBackupDir} ] && mkdir -p ${zookeeperBackupDir}

	if [ -s ${zookeeperBackupDir}/${backupDate}.zip ]
	then
		logWrite INFO "${zookeeperBackupDir}/${backupDate}.zip is already exists. so skip backup."
	else
		cp ${zookeeperSourceDir}/${backupDate}.zip ${zookeeperBackupDir}
		if [ -s ${zookeeperBackupDir}/${backupDate}.zip ]
		then
			logWrite INFO "${zookeeperBackupDir}/${backupDate}.zip Backup Success."
		else
			logWrite FAIL "${zookeeperBackupDir}/${backupDate}.zip Backup Fail."
		fi
	fi
}

function mariadbBackup(){
	local backupDate=`date +%Y%m%d -d '1 day ago'`

	[ ! -d ${mariadbBackupDir} ] && mkdir -p ${mariadbBackupDir}

	if [ -s ${mariadbBackupDir}/${backupDate}.zip ]
	then
		logWrite INFO "${mariadbBackupDir}/${backupDate}.zip is already exists. so skip backup"
	else
		cp ${mariadbSourceDir}/${backupDate}.zip ${mariadbBackupDir}
		if [ -s ${mariadbBackupDir}/${backupDate}.zip ]
		then
			logWrite INFO "${mariadbBackupDir}/${backupDate}.zip Backup Success."
		else
			logWrite FAIL "${mariadbBackupDir}/${backupDate}.zip Backup Fail."
		fi
	fi
}

function checkOnOffAndRun(){
	local componentType=$1
	local componentOnOff=$2

	if [[ ${componentOnOff} == [Oo][Nn] ]]; then
		logWrite INFO "${componentType} is ${componentOnOff}. start ${componentType}."
		${componentType}
	else
		logWrite INFO "${componentType} is ${componentOnOff}. skip ${componentType}."
	fi
}

function main(){
	logWrite INFO "components backup schedules start."
	logWrite INFO "=====================SETTINGS====================="
	logWrite INFO "solrBackupOnOff      = ${solrBackupOnOff}"
	logWrite INFO "nosqlBackupOnOff     = ${nosqlBackupOnOff}"
	logWrite INFO "zookeeperBackupOnOff = ${zookeeperBackupOnOff}"
	logWrite INFO "mariadbBackupOnOff   = ${mariadbBackupOnOff}"
	logWrite INFO "solrBackupDir        = ${solrBackupDir}"
	logWrite INFO "mariadbBackupDir     = ${mariadbBackupDir}"
	logWrite INFO "nosqlBackupDir       = ${nosqlBackupDir}"
	logWrite INFO "zookeeperBackupDir   = ${zookeeperBackupDir}"
	logWrite INFO "logDir               = ${logDir}"
	logWrite INFO "nodeID               = ${nodeID}"
	logWrite INFO "nodeIP               = ${nodeIP}"
	logWrite INFO "activePort           = ${activePort}"
	logWrite INFO "=================================================="

	checkOnOffAndRun solrBackup ${solrBackupOnOff}
	checkOnOffAndRun nosqlBackup ${nosqlBackupOnOff}
	checkOnOffAndRun zookeeperBackup ${zookeeperBackupOnOff}
	checkOnOffAndRun mariadbBackup ${mariadbBackupOnOff}

	logWrite INFO "coponents backup schedules end."
}

main

#!/bin/bash
# Preferences
source /home/freesia/scripts/fudf.sh
source /home/freesia/scripts/FreesiaSysEnv.sh
loadProperties "${FREESIA_PROPS_FILE}"

# Process Setting
statusSolr=oN
statusStatusmgr=on

# Period Setting
checkPeriodSecSolr=5
checkPeriodSecStatusManager=10

# Log Path
logDir=/data/log/monitor

# Log Write
function logWrite(){
local logDate=`date +%F`
local logTime=`date +%F" "%T.%3N`
local logName=${1}
local logLevel=${2}
local logBody=${3}

[ ! -d ${logdir}/${logName} ] && mkdir -p ${logDir}/${logName}

echo "${logTime},${logName},${logLevel},${logBody}" >> ${logDir}/${logName}/${logName}_${logDate}.log
}

# Restart
function restartSolr(){
local restartSolrPort=$1

${CMD_SOLR} restart ${restartSolrPort} > /dev/null 2> /dev/null
}

function restartStatusManager(){
${CMD_PROCSTATUS} start > /dev/null 2> /dev/null
}

# Main_Solr
function mainSolr(){
if [[ ${statusSolr} == [Oo][Nn] ]];
then
	while true
	do
		logWrite Solr INFO "Solr status detect start"

		nodeID="${PROPS[node.id]}"
		nodeIP="${PROPS[host.ip]}"
		nodeName="${PROPS[host.name]}"
		activePort=`${CMD_FADMCTL} se --list | grep ${nodeID} | grep ${nodeIP} | grep active | awk '{print $9}' | head -1`
		collectionStatusAPI="curl -s http://${nodeIP}:${activePort}/solr/admin/collections?action=CLUSTERSTATUS"
		collectionListAPI="http://${nodeIP}:${activePort}/solr/admin/collections?action=LIST&wt=json"
		collectionList=`curl -s "${collectionListAPI}" | jq -r '.collections[]' | egrep ^[0-9][0-9] | sort -n`

		logWrite Solr INFO "#################################################settings#################################################"
		logWrite Solr INFO "checkPeriodSec      = ${checkPeriodSecSolr}"
		logWrite Solr INFO "logDir              = ${logDir}/solr/"
		logWrite Solr INFO "nodeID              = ${nodeID}"
		logWrite Solr INFO "nodeIP              = ${nodeIP}"
		logWrite Solr INFO "nodeName            = ${nodeName}"
		logWrite Solr INFO "activePort          = ${activePort}"
		logWrite Solr INFO "collectionStatusAPI = ${collectionStatusAPI}"
		logWrite Solr INFO "collectionListAPI   = ${collectionListAPI}"
		logWrite Solr INFO "##########################################################################################################"

		if [ -z ${activePort} ];
		then
			logWrite Solr ERROR "All solr port in down. So stop scripts."
			exit 1
		fi

		for collectionName in `echo ${collectionList} | sort -n`
		do
			errorNode=(`${collectionStatusAPI} | jq -r ".cluster.collections.\"${collectionName}\".shards[].replicas[] | select(.state==\"down\") | .node_name" | grep ${nodeName}`)
			if [ ! -z ${errorNode} ] && [ ${errorNode} != "null" ];
			then
				restartSolrPort=`echo ${errorNode} | cut -d: -f2 | cut -d_ -f1`
				logWrite Solr ERROR "${collectionName} ${errorNode} status is down. restart ${nodeName} Solr ${restartSolrPort}."
				logWrite Solr INFO "${errorNode} ${restartSolrPort} restart."
				restartSolr ${restartSolrPort}
				if [ $? -eq 0 ];
				then
					logWrite Solr SUCCESS "Solr ${restartSolrPort} restart success."
				else
					logWrite Solr FAIL "Solr ${restartSolrPort} restart fail."
				fi
			else
				logWrite Solr INFO "${collectionName} is OK."
			fi
		done
		logWrite Solr INFO "Solr status detect finished. sleep ${checkPeriodSecSolr} Secs."
		sleep ${checkPeriodSecSolr}
	done
	
else
	logWrite Solr INFO "Solr Monitor is Disabled..."
	exit 
fi

}

# Main_StatusManager

function mainStatusManager(){
if [[ ${statusStatusmgr} == [Oo][Nn] ]];
then
	logWrite StatusManager INFO ":::: PROCESS STATUS DETECT START..!"
	logWrite StatusManager INFO "-------------------------------------------- S E T T I N G S ---------------------------------------------"
	logWrite StatusManager INFO "- PROCESS NAME        = StatusManager                                                                     "
	logWrite StatusManager INFO "- CHECK PERIOD SEC    = ${checkPeriodSecStatusManager} sec.                                               "
	logWrite StatusManager INFO "- LOG DIRECTORY       = ${logDir}/StatusManager/                                                          "
	logWrite StatusManager INFO "----------------------------------------------------------------------------------------------------------"

	while true
	do
		${CMD_PROCSTATUS} status | grep "is not running" > /dev/null
		if [ $? -eq 0 ];
		then 
			logWrite StatusManager ERROR "StatusManager is Down. The Process will be Started... "
			restartStatusManager
			
			if [ $? -eq 0 ];
			then
				logWrite StatusManager SUCCESS "StatusManager Start SUCCESS..!"
			else
				logWrite StatusManager FAIL "StatusManager is Fail..!"
			fi
		else
			logWrite StatusManager INFO "Statusmanager is OK..!"
		fi

		logWrite StatusManager INFO "Process status detect finished. sleep ${checkPeriodSecStatusManager} Secs..."
		sleep ${checkPeriodSecStatusManager}
	done
else
	logWrite StatusManager INFO "StatusManager Monitor is Disabled... "
	exit 
fi
}

mainSolr &
mainStatusManager &

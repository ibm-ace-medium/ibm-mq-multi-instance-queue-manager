#!/bin/bash

RUNNING="(Running)"
RUNNING_AS_STANDBY="(Running as standby)"
SLEEP_FOR_SECONDS=15
QUEUE_MANAGER_NAME=


isMQConfigured() {

  if dspmqinf ${QUEUE_MANAGER_NAME}; then
      echo "${QUEUE_MANAGER_NAME} is configured" >> /MQHA/qmgrs/container.log
  else
      if [[ "${IS_ACTIVE_NODE}" == 1 ]]; then
        configureActiveNode
      else
        configureStandByNode
      fi
  fi
}

configureActiveNode() {
  echo "Configuring active node..."
  /home/mqm/mq-setup.sh ${QUEUE_MANAGER_NAME} 1414 mqadmins ${LOG_FILES_DIR_ENV} ${DATA_FILES_DIR_ENV}
}

configureStandByNode() {
  echo "Configuring standby node..."
  addmqinf -s QueueManager -v Name=${QUEUE_MANAGER_NAME} -v Directory=${QUEUE_MANAGER_NAME} -v Prefix=/var/mqm -v DataPath=${DATA_FILES_DIR_ENV}/${QUEUE_MANAGER_NAME} >> /MQHA/qmgrs/container.log
  strmqm -x ${QUEUE_MANAGER_NAME} >> /MQHA/qmgrs/container.log
}

isRunningQM() {
  local qmgrName=$1
  local qmgrStatus="$(dspmq | grep ${qmgrName})"
  echo "qmgrName ${qmgrName}"
  echo "qmgrStatus ${qmgrStatus}"

  # Keep container live while Queue Manager is Running
  while [[ "${qmgrStatus}" == *"${RUNNING}"* ]] || [[ "${qmgrStatus}" == *"${RUNNING_AS_STANDBY}"* ]]; do
    sleep $SLEEP_FOR_SECONDS
    echo "Heartbeat..."
    qmgrStatus="$(dspmq | grep ${qmgrName})"
  done
}

start() {
  QUEUE_MANAGER_NAME=$1

  isMQConfigured

  strmqm -x ${QUEUE_MANAGER_NAME}
  source /var/scripts/init.sh ${QUEUE_MANAGER_NAME} || true
  isRunningQM ${QUEUE_MANAGER_NAME}
}

start $1

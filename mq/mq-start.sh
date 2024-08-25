#!/bin/bash

RUNNING="(Running)"
RUNNING_AS_STANDBY="(Running as standby)"
SLEEP_FOR_SECONDS_ENV=
QUEUE_MANAGER_NAME_ENV=
QUEUE_MANAGER_PORT_ENV=
MQ_ADMINS_GROUP_ENV=


isMQConfigured() {
  if dspmqinf ${QUEUE_MANAGER_NAME_ENV}; then
      echo "${QUEUE_MANAGER_NAME_ENV} is configured" >> /MQHA/qmgrs/container.log
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
  /home/mqm/mq-setup.sh ${QUEUE_MANAGER_NAME_ENV} ${QUEUE_MANAGER_PORT_ENV} ${MQ_ADMINS_GROUP_ENV} ${LOG_FILES_DIR_ENV} ${DATA_FILES_DIR_ENV}
}

configureStandByNode() {
  echo "Configuring standby node..."
  addmqinf -s QueueManager -v Name=${QUEUE_MANAGER_NAME_ENV} -v Directory=${QUEUE_MANAGER_NAME_ENV} -v Prefix=/var/mqm -v DataPath=${DATA_FILES_DIR_ENV}/${QUEUE_MANAGER_NAME_ENV} >> /MQHA/qmgrs/container.log
  strmqm -x ${QUEUE_MANAGER_NAME_ENV} >> /MQHA/qmgrs/container.log
}

isRunningQM() {
  local qmgrName=$1

  # Get current status of Queue Manager
  local qmgrStatus="$(dspmq | grep ${qmgrName})"

  # Keep container live while Queue Manager is Running
  while [[ "${qmgrStatus}" == *"${RUNNING}"* ]] || [[ "${qmgrStatus}" == *"${RUNNING_AS_STANDBY}"* ]]; do
    sleep $SLEEP_FOR_SECONDS_ENV
    echo "Heartbeat..."
    qmgrStatus="$(dspmq | grep ${qmgrName})"
  done
}

start() {
  isMQConfigured

  strmqm -x ${QUEUE_MANAGER_NAME_ENV}
  source /var/scripts/init.sh ${QUEUE_MANAGER_NAME_ENV} || true
  isRunningQM ${QUEUE_MANAGER_NAME_ENV}
}

start

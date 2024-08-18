#!/bin/bash

NFS_STORAGE_PATH=/home/ivansla/Repositories/ibm-ace-medium/ibm-mq-multi-instance-queue-manager/data/nfs-storage

QUEUE_MANAGER_DIR=/MQHA/qmgrs
LOG_FILES_DIR=${QUEUE_MANAGER_DIR}/logs
DATA_FILES_DIR=${QUEUE_MANAGER_DIR}/data
SLEEP_FOR_SECONDS=15

clean() {
  # Clean external MQ files
  sudo rm -rf ${NFS_STORAGE_PATH}/qmgrs/

  # Clean MQ SERVER
  docker container stop QM1-active
  docker container rm QM1-active
  docker container stop QM1-standby
  docker container rm QM1-standby

  # Clean NFS SERVER
  docker container stop nfs-server
  docker container rm nfs-server
  docker volume rm nfs-volume

  # Create network
  docker network rm my-network
}

buildImages() {
  # Build base image for all other images with necessary tools
  docker build --no-cache --tag=my-docker-repository/rhel-base ./rhel

  # Build MQ base image
  docker build --no-cache --tag=my-docker-repository/mq-install:9.3.5.0 ./mq/base

  # Build MQ main image
  docker build --no-cache --tag=my-docker-repository/mq-multi-instance ./mq
}

startNfsServerAndCreateNfsVolume() {
  # Start NFS Server
  docker run -itd --privileged --name nfs-server \
    -e SHARED_DIRECTORY=/data \
    -v ${NFS_STORAGE_PATH}:/data \
    itsthenetwork/nfs-server-alpine:12

  docker network connect my-network nfs-server
  docker network inspect my-network

  nfsServerIpAddress=$(docker network inspect my-network | grep IPv4Address)
  extractedNfsServerIpAddress=$(echo "${nfsServerIpAddress}" | sed 's/^.*: \"//' | sed 's/\/.*//')

  docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=${extractedNfsServerIpAddress},vers=4,hard,intr,rw \
  --opt device=:/ \
  nfs-volume
}

createNetwork() {
  docker network create my-network
}

runActiveMqContainer() {
  # Start MQ Server Active Node
  docker run -dt --restart unless-stopped \
    -e IS_ACTIVE_NODE=1 \
    -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} \
    -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} \
    --mount source=nfs-volume,target=/MQHA \
    --name QM1-active my-docker-repository/mq-multi-instance

  docker network connect my-network QM1-active
}

runStandbyMqContainer() {
  # Start MQ Server StandBy Node
  docker run -dt --restart unless-stopped \
    -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} \
    -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} \
    --mount source=nfs-volume,target=/MQHA \
    --name QM1-standby my-docker-repository/mq-multi-instance

  docker network connect my-network QM1-standby
}

setupHA() {
  clean
  buildImages
  createNetwork
  startNfsServerAndCreateNfsVolume
  runActiveMqContainer
  waitUntilConfigurationIsFinished
  runStandbyMqContainer

  echo " All started."
  exit 0
}

waitUntilConfigurationIsFinished() {
  echo -n "Please wait until configured."
  FILE=${NFS_STORAGE_PATH}/qmgrs/data/QMgr01/qm.ini
  while [[ ! -f "$FILE" ]]; do
    sleep ${SLEEP_FOR_SECONDS}
    echo -n "."
  done
}

setupHA
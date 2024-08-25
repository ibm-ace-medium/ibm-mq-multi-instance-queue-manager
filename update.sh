#!/bin/bash

#NFS_STORAGE_PATH=/home/ivansla/Repositories/ibm-ace-medium/ibm-mq-multi-instance-queue-manager/data/nfs-storage
NFS_STORAGE_PATH="update me"
QUEUE_MANAGER_NAME="QMgr01"
QUEUE_MANAGER_PORT="1414"
MQ_ADMINS_GROUP="mqadmins"
SLEEP_FOR_SECONDS=15

MQ_FILE=9.3.5.0-IBM-MQ-Advanced-for-Developers-LinuxX64.tar.gz
MQ_URL=https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/${MQ_FILE}

# You can uncomment this line if you have the file on your local machine and can run http server with python.
# In order to run http server, navigate to directory where you have MQ installation file and execute the command:
# python3 -m http.server 9000
# MQ_URL=http://replace_with_your_ip_address:9000/$MQ_FILE

QUEUE_MANAGER_DIR=/MQHA/qmgrs
LOG_FILES_DIR=${QUEUE_MANAGER_DIR}/logs
DATA_FILES_DIR=${QUEUE_MANAGER_DIR}/data

clean() {
  # Clean external MQ files. Sudo is required as I don't have mqm user on my host.
  sudo rm -rf ${NFS_STORAGE_PATH}/qmgrs/
  mkdir -p ${NFS_STORAGE_PATH}

  # Clean MQ SERVER
  docker container stop QM1-standby
  docker container rm QM1-standby
  docker container stop QM1-active
  docker container rm QM1-active

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
  docker build --no-cache --build-arg MQ_URL=${MQ_URL} --build-arg MQ_ADMINS_GROUP=${MQ_ADMINS_GROUP} --tag=my-docker-repository/mq-install:9.3.5.0 ./mq/base

  # Build MQ main image
  docker build --no-cache --tag=my-docker-repository/mq-multi-instance ./mq
}

createNetwork() {
  docker network create my-network
}

startNfsServerAndCreateNfsVolume() {
  # Start NFS Server
  docker run -dt --restart unless-stopped --privileged --name nfs-server \
    -e SHARED_DIRECTORY=/data \
    -v ${NFS_STORAGE_PATH}:/data \
    itsthenetwork/nfs-server-alpine:12

  docker network connect my-network nfs-server
  docker network inspect my-network

  # Extract the NFS Server container IP Address and pass it into volume creation
  nfsServerIpAddress=$(docker network inspect my-network | grep IPv4Address)
  extractedNfsServerIpAddress=$(echo "${nfsServerIpAddress}" | sed 's/^.*: \"//' | sed 's/\/.*//')

  docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=${extractedNfsServerIpAddress},vers=4,hard,intr,rw \
  --opt device=:/ \
  nfs-volume
}

runActiveMqContainer() {
  # Start MQ Server Active Node
  docker run -dt --restart unless-stopped \
    -e IS_ACTIVE_NODE=1 \
    -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} \
    -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} \
    -e QUEUE_MANAGER_NAME_ENV=${QUEUE_MANAGER_NAME} \
    -e QUEUE_MANAGER_PORT_ENV=${QUEUE_MANAGER_PORT} \
    -e MQ_ADMINS_GROUP_ENV=${MQ_ADMINS_GROUP} \
    -e SLEEP_FOR_SECONDS_ENV=${SLEEP_FOR_SECONDS} \
    --mount source=nfs-volume,target=/MQHA \
    --name QM1-active my-docker-repository/mq-multi-instance

  docker network connect my-network QM1-active
}

runStandbyMqContainer() {
  # Start MQ Server StandBy Node
  docker run -dt --restart unless-stopped \
    -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} \
    -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} \
    -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} \
    -e QUEUE_MANAGER_NAME_ENV=${QUEUE_MANAGER_NAME} \
    -e QUEUE_MANAGER_PORT_ENV=${QUEUE_MANAGER_PORT} \
    -e SLEEP_FOR_SECONDS_ENV=${SLEEP_FOR_SECONDS} \
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

  echo "All started."
  exit 0
}

waitUntilConfigurationIsFinished() {
  echo -n "Please wait until configured."
  FILE=${NFS_STORAGE_PATH}/qmgrs/data/QMgr01/qm.ini
  while [[ ! -f "$FILE" ]]; do
    sleep ${SLEEP_FOR_SECONDS}
    echo -n "."
  done
  echo ""
}

setupHA
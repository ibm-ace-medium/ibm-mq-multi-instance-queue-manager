export QUEUE_MANAGER_DIR=/MQHA/qmgrs
export LOG_FILES_DIR=${QUEUE_MANAGER_DIR}/logs
export DATA_FILES_DIR=${QUEUE_MANAGER_DIR}/data

# Clean MQ SERVER
docker build --no-cache --tag=my-docker-repository/mq-multi-instance .
docker container stop QM1-active
docker container rm QM1-active
docker container stop QM1-standby
docker container rm QM1-standby

# Clean NFS SERVER
docker container stop nfs-server
docker container rm nfs-server

# clean external MQ files
docker volume rm nfs-volume
sudo rm -rf /home/ivansla/Repositories/ibm-ace-medium/ibm-mq-multi-instance-queue-manager/data/nfs-storage/qmgrs/


# Start NFS Server
docker run -itd --privileged --restart unless-stopped --name nfs-server -e SHARED_DIRECTORY=/data -v /home/ivansla/Repositories/ibm-ace-medium/ibm-mq-multi-instance-queue-manager/data/nfs-storage:/data itsthenetwork/nfs-server-alpine:12
docker network connect my-network nfs-server
docker network inspect my-network

docker volume create --driver local \
--opt type=nfs \
--opt o=addr=172.19.0.2,vers=4,hard,intr,rw,sync \
--opt device=:/ \
nfs-volume

# Start MQ Server
docker run -dt --restart unless-stopped -e IS_ACTIVE_NODE=1 -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} --mount source=nfs-volume,target=/MQHA --name QM1-active my-docker-repository/mq-multi-instance
# giving a small time to start active node
sleep 3
docker run -dt --restart unless-stopped -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} --mount source=nfs-volume,target=/MQHA --name QM1-standby my-docker-repository/mq-multi-instance
docker network connect my-network QM1-active
docker network connect my-network QM1-standby
docker network inspect my-network
docker ps

#sudo docker exec -ti QM1-active bash
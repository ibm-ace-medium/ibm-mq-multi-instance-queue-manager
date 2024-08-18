export NFS_STORAGE_PATH=~/nfs-storage

mkdir -p ${NFS_STORAGE_PATH}
chmod o+rwx ${NFS_STORAGE_PATH}

# Clean NFS SERVER
docker container stop my-rhel
docker container rm my-rhel
docker container stop nfs-server
docker container rm nfs-server

# clean external MQ files
docker volume rm nfs-volume
rm -f ${NFS_STORAGE_PATH}/*

# Start NFS Server
docker run -itd --privileged --name nfs-server -e SHARED_DIRECTORY=/data -v ${NFS_STORAGE_PATH}:/data itsthenetwork/nfs-server-alpine:12
docker network rm nfs-server-network
docker network create nfs-server-network
docker network connect nfs-server-network nfs-server
docker network inspect nfs-server-network


nfsServerIpAddress=$(docker network inspect nfs-server-network | grep IPv4Address)
nfsServerIpAddress=$(echo "${nfsServerIpAddress}" | sed 's/^.*: \"//' | sed 's/\/.*//')
echo ${nfsServerIpAddress}

docker volume create --driver local \
--opt type=nfs \
--opt o=addr=${nfsServerIpAddress},vers=4,hard,intr,rw,sync \
--opt device=:/ \
nfs-volume

docker volume inspect nfs-volume
docker run -dt --mount source=nfs-volume,target=/nfs-storage --name my-rhel my-docker-repository/rhel-base
docker exec -ti my-rhel bash


#docker run -dt --rm --mount source=nfs-volume,target=/MQHA --name QM1-active my-docker-repository/mq-multi-instance
#
## Start MQ Server
#docker run -dt --restart unless-stopped -e IS_ACTIVE_NODE=1 -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} --mount source=nfs-volume,target=/MQHA --name QM1-active my-docker-repository/mq-multi-instance
## giving a small time to start active node
#sleep 3
#docker run -dt --restart unless-stopped -e LOG_FILES_DIR_ENV=${LOG_FILES_DIR} -e DATA_FILES_DIR_ENV=${DATA_FILES_DIR} --mount source=nfs-volume,target=/MQHA --name QM1-standby my-docker-repository/mq-multi-instance
#docker network connect my-network QM1-active
#docker network connect my-network QM1-standby
#docker network inspect my-network
#docker ps

#sudo docker exec -ti QM1-active bash
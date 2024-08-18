sudo docker container stop nfs-server
sudo docker container rm nfs-server
sudo docker run -itd --privileged --restart unless-stopped --name nfs-server -e SHARED_DIRECTORY=/data -v /home/ivansla/Repositories/ibm-ace-medium/ibm-mq-multi-instance-queue-manager/data/nfs-storage:/data itsthenetwork/nfs-server-alpine:12
sudo docker network connect my-network nfs-server
sudo docker network inspect my-network
sudo docker exec -ti nfs-server bash
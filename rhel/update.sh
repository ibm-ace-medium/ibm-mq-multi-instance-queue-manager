sudo docker build --no-cache --tag=my-docker-repository/rhel-base .

#sudo docker container stop rhel
#sudo docker container rm rhel
#sudo docker run -itd --privileged --restart unless-stopped --mount type=volume,source=nfs-volume,target=/mnt --name rhel registry.access.redhat.com/ubi8/ubi
#sudo docker run -itd --privileged --restart unless-stopped --mount type=volume,source=nfs-volume,target=/mnt --name rhel registry.access.redhat.com/ubi8/ubi
#sudo docker network connect my-network rhel
#sudo docker network inspect my-network
#sudo docker exec -ti rhel bash

#sudo docker run -dt --privileged --mount source=nfs-volume,target=/MQHA --name QM1 my-docker-repository/mq-multi-instance
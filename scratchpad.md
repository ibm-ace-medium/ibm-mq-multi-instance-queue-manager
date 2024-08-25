# python3 -m http.server 9000
# ibm-mq-multi-instance-queue-manager
# https://www.baeldung.com/linux/docker-mount-nfs-shares
# https://docs.fedoraproject.org/en-US/epel/
# yum --nogpgcheck --repofrompath=centos,https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/ install -y nfs-utils --allowerasing


# To run as a non-root user
# 1) Create the user and group outside the container with a selected uid/gid
# groupadd -r -g 1010 mqm
# useradd -r  -s /sbin/nologin -g mqm -u 1010 mqm


sudo mount -v -o vers=4,loud 172.19.0.2:/ /mnt/MQHA
sudo mount -v -o vers=4,hard,intr,rw 172.19.0.2:/ /mnt/MQHA
sudo umount /mnt/MQHA


docker volume create --driver local \
--opt type=nfs \
--opt o=addr=172.19.0.2,vers=4,hard,intr,rw \
--opt device=:/ \
nfs-volume


docker volume create --driver local \
--opt type=nfs \
--opt o=addr=172.19.0.3,vers=4,hard,intr,rw \
--opt device=:/data \
nfs-volume
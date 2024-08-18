sudo docker build --tag=my-docker-repository/mq-multi-instance-base .
#sudo docker container stop QM1
#sudo docker container rm QM1
#sudo docker run -dt --name QM1 my-docker-repository/mq-install:9.3.5.0
#sudo docker exec -ti QM1 bash
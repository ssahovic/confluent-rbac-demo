#!/bin/bash -e
echo "Start RBAC setup " > /home/ec2-user/rbac.log
 # make sure dependencies are installed
depends="openssl docker-compose docker confluent jq"
for value in $depends
do
    if ! check="$(type -p "$value")" || [[ -z check ]]; then
        echo "error: please install '$value' and retry" >> /home/ec2-user/rbac.log
        exit 1
    fi
done

if [ -z "$1" ]; then
    PROJECT=rbac
else
    PROJECT=$1
fi

# Generating public and private keys for token signing
echo "Generating public and private keys for token signing" >> /home/ec2-user/rbac.log
mkdir -p ./conf
openssl genrsa -out ./conf/keypair.pem 2048
openssl rsa -in ./conf/keypair.pem -outform PEM -pubout -out ./conf/public.pem

# start broker
echo
echo "Starting Zookeeper, OpenLDAP and Kafka with MDS" >> /home/ec2-user/rbac.log
docker-compose -p $PROJECT up -d broker

# wait for kafka container to be healthy
source ./functions.sh
echo
echo "Waiting for the broker to be healthy" >> /home/ec2-user/rbac.log
retry 10 5 container_healthy broker

# set role bindings
echo
echo "Creating role bindings for service accounts" >> /home/ec2-user/rbac.log
./create-role-bindings.sh

# start the rest of the cluster
echo
echo "Starting the rest of the services" >> /home/ec2-user/rbac.log
docker-compose -p $PROJECT up -d

echo
echo "----------------------------------------------" >> /home/ec2-user/rbac.log
echo
echo "Started confluent cluster with rbac." >> /home/ec2-user/rbac.log
echo "Kafka is available at localhost:9092" >> /home/ec2-user/rbac.log
echo
echo "    See status:" >> /home/ec2-user/rbac.log
echo "          docker-compose -p $PROJECT ps" >> /home/ec2-user/rbac.log
echo "    To stop:" >> /home/ec2-user/rbac.log
echo "          docker-compose -p $PROJECT down" >> /home/ec2-user/rbac.log



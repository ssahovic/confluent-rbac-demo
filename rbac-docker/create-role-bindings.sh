#!/bin/bash -e

################################## GET KAFKA CLUSTER ID ########################
ZK_CONTAINER=zookeeper
ZK_PORT=2181
echo "Retrieving Kafka cluster id from docker-container '$ZK_CONTAINER' port '$ZK_PORT'" >> /home/ec2-user/rbac.log
#docker exec -it $ZK_CONTAINER zookeeper-shell localhost:$ZK_PORT get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id
#KAFKA_CLUSTER_ID=$(docker exec -it $ZK_CONTAINER zookeeper-shell localhost:$ZK_PORT get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
#docker exec -it zookeeper zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id
zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id
#KAFKA_CLUSTER_ID=$(docker exec -it zookeeper zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
KAFKA_CLUSTER_ID=$(zookeeper-shell localhost:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
echo "KAFKA_CLUSTER_ID: $KAFKA_CLUSTER_ID" >> /home/ec2-user/rbac.log
if [ -z "$KAFKA_CLUSTER_ID" ]; then 
    echo "Failed to retrieve kafka cluster id from zookeeper" >> /home/ec2-user/rbac.log
    exit 1
fi

################################## SETUP VARIABLES #############################
MDS_URL=http://localhost:8090
# Standard connect cluster id
# get connect cluster id curl -u fry:fry http://localhost:8083/permissions
CONNECT=connect-cluster
# standard SR cluster id curl -u leela:leela http://localhost:8081/permissions
SR=schema-registry
KSQL=ksql-cluster
# standard ksql cluster id curl -u professor:professor "http://localhost:8088/info" | jq '.'
KSQLSERVICEID=default_
# C3 cluster id, is not used
C3=c3-cluster

# User
SUPER_USER=professor
SUPER_USER_PASSWORD=professor
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
CONNECT_PRINCIPAL="User:fry"
SR_PRINCIPAL="User:leela"
#KSQL_PRINCIPAL="User:zoidberg"
KSQL_PRINCIPAL="User:professor"
C3_PRINCIPAL="User:hermes"

# Log into MDS
if [[ $(type expect 2>&1) =~ "not found" ]]; then
  echo "'expect' is not found. Install 'expect' and try again" >> /home/ec2-user/rbac.log
  exit 1
fi
echo -e "\n# Login"
OUTPUT=$(
expect <<END
  log_user 1
  spawn confluent login --url $MDS_URL
  expect "Username: "
  send "${SUPER_USER}\r";
  expect "Password: "
  send "${SUPER_USER_PASSWORD}\r";
  expect "Logged in as "
  set result $expect_out(buffer)
END
)
echo "$OUTPUT"
if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
  echo "Failed to log into your Metadata Server.  Please check all parameters and run again" >> /home/ec2-user/rbac.log
  exit 1
fi

################################### SETUP SUPERUSER ###################################
echo "Creating Super User role bindings" >> /home/ec2-user/rbac.log

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL  \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

confluent iam rolebinding create \
    --principal $SUPER_USER_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQLSERVICEID

################################### SCHEMA REGISTRY ###################################
echo "Creating Schema Registry role bindings" >> /home/ec2-user/rbac.log

# SecurityAdmin on SR cluster itself
confluent iam rolebinding create \
    --principal $SR_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --schema-registry-cluster-id $SR

# ResourceOwner for groups and topics on broker
for resource in Topic:_schemas Group:schema-registry
do
    confluent iam rolebinding create \
        --principal $SR_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### CONNECT ###################################
echo "Creating Connect role bindings" >> /home/ec2-user/rbac.log

# SecurityAdmin on the connect cluster itself
confluent iam rolebinding create \
    --principal $CONNECT_PRINCIPAL \
    --role SecurityAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT

# ResourceOwner for groups and topics on broker
declare -a ConnectResources=(
    "Topic:connect-configs" 
    "Topic:connect-offsets" 
    "Topic:connect-status" 
    "Group:connect-cluster" 
    "Group:secret-registry" 
    "Topic:_secrets"
)
for resource in ${ConnectResources[@]}
do
    confluent iam rolebinding create \
        --principal $CONNECT_PRINCIPAL \
        --role ResourceOwner \
        --resource $resource \
        --kafka-cluster-id $KAFKA_CLUSTER_ID
done

################################### KSQL ###################################
echo "Creating KSQL role bindings" >> /home/ec2-user/rbac.log

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource KsqlCluster:ksql-cluster \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --ksql-cluster-id $KSQLSERVICEID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Group:_confluent-ksql-${KSQLSERVICEID} \
    --prefix \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:_confluent-ksql-${KSQLSERVICEID}_command_topic \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

confluent iam rolebinding create \
    --principal $KSQL_PRINCIPAL \
    --role ResourceOwner \
    --resource Topic:${KSQLSERVICEID}ksql_processing_log \
    --kafka-cluster-id $KAFKA_CLUSTER_ID

################################### C3 ###################################
echo "Creating C3 role bindings" >> /home/ec2-user/rbac.log

# C3 only needs SystemAdmin on the kafka cluster itself
confluent iam rolebinding create \
    --principal $C3_PRINCIPAL \
    --role SystemAdmin \
    --kafka-cluster-id $KAFKA_CLUSTER_ID


######################### print cluster ids and users again to make it easier to copypaste ###########

echo "Finished setting up role bindings"  >> /home/ec2-user/rbac.log
echo "    kafka cluster id: $KAFKA_CLUSTER_ID"  >> /home/ec2-user/rbac.log
echo "    connect cluster id: $CONNECT"  >> /home/ec2-user/rbac.log
echo "    schema registry cluster id: $SR"  >> /home/ec2-user/rbac.log
echo "    ksql cluster id: $KSQLSERVICEID"  >> /home/ec2-user/rbac.log
echo
echo "    super user account: $SUPER_USER_PRINCIPAL" >> /home/ec2-user/rbac.log
echo "    connect service account: $CONNECT_PRINCIPAL" >> /home/ec2-user/rbac.log
echo "    schema registry service account: $SR_PRINCIPAL" >> /home/ec2-user/rbac.log
echo "    KSQL service account: $KSQL_PRINCIPAL"  >> /home/ec2-user/rbac.log
echo "    C3 service account: $C3_PRINCIPAL"  >> /home/ec2-user/rbac.log

echo
echo "To set service IDs as environment variables paste/run this in your shell:"  >> /home/ec2-user/rbac.log
echo "    export KAFKA_ID=$KAFKA_CLUSTER_ID ; export CONNECT_ID=$CONNECT ; export SR_ID=$SR ; export KSQL_ID=$KSQLSERVICEID"  >> /home/ec2-user/rbac.log

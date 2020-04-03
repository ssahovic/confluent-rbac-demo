# Confluent Platform 5.4 Role-Based Access Control (RBAC) Hands-on Workshop

Role based access control (RBAC) was introduced in Confluent Platform version 5.3 as a preview feature. With Confluent Platform 5.4 RBAC is now production ready.

This github project describes a Hands-on Workshop around Confluent RBAC. The structure of the Hands-on is as followed
* Explaining and Introduce Role based Access Control
* Labs: Get to know the environment
* Advanced explanation of Role based Access Control
* RBAC Labs for try-out learnings

In general, the hands-on will take 4 hours.

# Environment for Hands-on Workshop Labs

To execute the Labs  you will have two possibilities
* run Docker-Compose on your own hardware/laptop [use docker-locally](rbac-docker/)
* create the demo environment in Cloud Provider infrastructure, [deploy cloud environment](terraform/)

## Prerequisites for running environment in Cloud
For an environment in cloud you need to setup following
- create SSH key and deploy in AWS/Google, I use the key name `hackathon-temp-key`
- intall terraform
- Having internet access
The cloud environment will install automatically everything you need. 

## Prerequisites for running environment on own hardware
For an environment on your hardware, you need
- Docker installed
- Java8 installed
- Confluent Platform 5.4 installed

### Optional
Install on your desktop Apache Directory Studio to create and modify LDAP users in openLDAP. [Download Apache Directory Studio](https://directory.apache.org/studio/downloads.html)
Apache Directory Studio is important if you want to add user/group in openLDAP or modify users or groups.

# Hands-on Execution
The structure of hands-on Workshop is as followed:
## Lab 1. Setup the Lab-Environment
First of all you need to setup the Lab-Environment. Here you have two possibilities
  * on your local machine, [goto docker-compose setup](rbac-docker/)
  * in cloud environment, [goto to terraform setup](terraform/)

If you run a Confluent leaded Hands-on Workshop, then Confluent can prepare a Lab-Environment in the cloud for you.

## Lab 2. Checking the Lab-Environment
Checking your lab environment
  * on your local machine, [goto Lab2-localmachine](labs/Lab2-localmachine.md)
  * in cloud , [goto to Lab2-cloud](labs/Lab2-cloud.md)

## Lab 3. First Authorization check
Execute the next Lab and check authorization:
* [Lab3](labs/Lab3.md)

## Lab 4. High level Hands-on with RBAC
* [Lab4](labs/Lab4.md)

# Stop
Outside of cloud compute, please use terraform, to really destroy the environment out of cloud:
```
terraform destroy
```
If you inside cloud compute you can stop the environment;
```
cd /home/ec2-user/software/confluent-rbac-hands-on-master/rbac-docker
docker-compose -p rbac down
```
A restart inside the compute:
```
./confluent_start.sh
```
On your local machine just execute
```
cd confluent-rbac-hands-on-master/rbac-docker
docker-compose -p rbac down
```

# Additional Information
Login to CLI as `professor:professor` as a super user to grant initial role bindings

```
# for running in cloud compute
confluent login --url http://localhost:8090
# for running on your local machine again cloud
confluent login --url http://pubip:8090
```

Set `KAFKA_CLUSTER_ID` in aws it is already prepared for you.

```
ZK_HOST=publicip:2181
KAFKA_CLUSTER_ID=$(zookeeper-shell $ZK_HOST get /cluster/id 2> /dev/null | grep version | jq -r .id)
```

Grant `User:bender` ResourceOwner to prefix `Topic:foo` on Kafka cluster `KAFKA_CLUSTER_ID`

```
confluent iam rolebinding create --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID --resource Topic:foo --prefix
```

List the roles of `User:bender` on Kafka cluster `KAFKA_CLUSTER_ID`
```
confluent iam rolebinding list --principal User:bender --kafka-cluster-id $KAFKA_CLUSTER_ID 
```

General Listing syntax
``` 
confluent iam rolebinding list User:[username] [clusters and resources you want to view their roles on]
```

General rolebinding syntax
```
confluent iam rolebinding create --role [role name] --principal User:[username] --resource [resource type]:[resource name] --[cluster type]-cluster-id [insert cluster id] 
```
available role types and permissions can be found [Here](https://docs.confluent.io/current/security/rbac/rbac-predefined-roles.html)
resource types include: Cluster, Group, Subject, Connector, TransactionalId, Topic

## Users and setup

---

| Description     | Name           | Role        |
| --------------- | -------------- | ----------- |
| Super User      | User:professor | SystemAdmin |
| Connect         | User:fry       | SystemAdmin |
| Schema Registry | User:leela     | SystemAdmin |
| KSQL            | User:professor | SystemAdmin |
| C3              | User:hermes    | SystemAdmin |
| Test User       | User:bender    | \<none>     |

- User `bender:bender` doesn't have any role bindings set up and can be used as a user under test
  - You can use `./client-configs/bender.properties` file to authenticate as `bender` from kafka console commands (like `kafka-console-producer`, `kafka-console-consumer`, `kafka-topics` and the like)
  - This file is also mounted into the broker docker container, so you can `docker-compose -p [project-name] exec broker /bin/bash` to open bash on broker and then use console commands with `/etc/client-configs/bender.properties`
  - When running console commands from inside the broker container, use `localhost:9092`
- All users have password which is the same as their user name, except `amy`. Her password I don't know, but it isn't `amy` :). So I usually connect to OpenLDAP via Apache Directory Studio and change her password to `amy`. Then use her as a second user under test.

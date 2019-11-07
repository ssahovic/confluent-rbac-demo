# Running RBAC on docker-compose in AWS

This docker-compose based setup includes:

- Zookeeper
- OpenLDAP
- Kafka with MDS, connected to the OpenLDAP
- Schema Registry
- KSQL
- Connect
- Rest Proxy
- C3
- install all utilities like jq, docker, expect, wget, unzip, java, ldap-tools

## Prerequisites

- create SSH key and deploy in AWS/Google, I use the key name `hackathon-temp-key`
---
The AWS Compute instance will everything prepare to run this demo, including
- docker
- Confluent Platform with all utilities installed
- `zookeeper-shell` must be on your `PATH`
- [Confluent CLI](https://docs.confluent.io/current/cli/index.html)
- VPCs and Security Group setup

### Optional
Install on your desktion Apache Directory Studio to create and modify LDAP users in openLDAP. [Download Apache Directory Studio](https://directory.apache.org/studio/downloads.html)
Apache Directory Studio is important if you want to add user/group in openLDAP or modify users or groups.

## Image Versions

We will use `PREFIX=confluentinc` and `TAG=5.3.1` for all images running via docker-compose. If you want to run newr docker images from Confluent, please change the `docker-compose.yml` file.


## Getting Started

---

To start confluent platform 5.3.1 including setup for RBC demo in AWS run

```
terraform init
terraform plan
terraform apply
```
Terraform will deploy the complete environment and start all service via docker-compose.
The output of terraform will show you all the endpoints:
```
terraform output
C3 =  Control Center: http://pubip:9021
CONNECT =  Connect: curl http://pubip:8083
KAFKA =  --bootstrap-Server pubip:9094
KSQL =  ksql http://pubip:8088
LDAP =  ldapsearch -D "cn=Hubert J. Farnsworth" -w professor -p 389 -h pubip -b "dc=planetexpress,dc=com" -s sub "(objectclass=*)"
MDS =  confluent login --url  http://pubip:8090
REST =  REST Proxy: curl  http://pubip:8082
SR =  Schema Registry: curl  http://pubip:8081
SSH =  SSH  Access: ssh -i ~/keys/hackathon-temp-key.pem ec2-user@pubip 
ZOOKEEPER =  --zookeeper pubip:2181
```

## login into compute instance
A AWS compute instance is created. You can login into AWS compute via
```
ssh -i hackathon-temp-key.epm ec2-user@PUBIP
```
The docker-compose project is `rbac`. docker-compose is after terraform deployment up and runnning.
You can use standard docker-compose commands like this listing all containers:
```
docker-compose -p rbac ps
```

or tail Control Center logs:

```
docker-compose -p rbac logs --t 200 -f control-center
```

The script will print you cluster ids to use in assigning role bindings

Kafka broker is available at `localhost:9094` (note, not 9092). All other services are at localhost with standard ports (e.g. C3 is 9021 etc).
In the AWS compute you can work with localhost, if you work from your local machine then please use the Public IP generated as output from terraform deployment

| Service         | Host:Port        |
| --------------- | ---------------- |
| Kafka           | `localhost:9094` |
| MDS             | `localhost:8090` |
| C3              | `localhost:9021` |
| Connect         | `localhost:8083` |
| KSQL            | `localhost:8088` |
| OpenLDAP        | `localhost:389`  |
| Schema Registry | `localhost:8081` |

### Granting Rolebindings

---

Login to CLI as `professor:professor` as a super user to grant initial role bindings

```
# for running in cloud compute
confluent login --url http://localhost:8090
# for running on your local machine again cloud
confluent login --url http://pubip:8090

```

Set `KAFKA_CLUSTER_ID`

```
ZK_HOST=localhost:2181
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
### Users

---

| Description     | Name           | Role        |
| --------------- | -------------- | ----------- |
| Super User      | User:professor | SystemAdmin |
| Connect         | User:fry       | SystemAdmin |
| Schema Registry | User:leela     | SystemAdmin |
| KSQL            | User:zoidberg  | SystemAdmin |
| C3              | User:hermes    | SystemAdmin |
| Test User       | User:bender    | \<none>     |

- User `bender:bender` doesn't have any role bindings set up and can be used as a user under test
  - You can use `./client-configs/bender.properties` file to authenticate as `bender` from kafka console commands (like `kafka-console-producer`, `kafka-console-consumer`, `kafka-topics` and the like)
  - This file is also mounted into the broker docker container, so you can `docker-compose -p [project-name] exec broker /bin/bash` to open bash on broker and then use console commands with `/etc/client-configs/bender.properties`
  - When running console commands from inside the broker container, use `localhost:9092`
- All users have password which is the same as their user name, except `amy`. Her password I don't know, but it isn't `amy` :). So I usually connect to OpenLDAP via Apache Directory Studio and change her password to `amy`. Then use her as a second user under test.

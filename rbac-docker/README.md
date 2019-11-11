# Running RBAC on docker-compose

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

see [Prerequisites](../README.md)


## Getting Started
you can deploy demo environment via terraform see [terraform-deploy](../terraform)
---
Or you start the demo environment on your local machine
```
git clone https://github.com/ora0600/confluent-rbac-demo.git
./confluent-start.sh
```
Doing hands-on see [Start-Page](../Readme.md)

To stop docker-compose setup:
```
docker-compose -p rbac down
```


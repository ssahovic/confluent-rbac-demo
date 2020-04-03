# Confluent Platform 5.4 Role-Based Access Control (RBAC) Hands-on Workshop

Role based access control (RBAC) was introduced in Confluent Platform version 5.3 as a preview feature. With Confluent Platform 5.4 RBAC is now production ready.

This github project describes a Hands-on Workshop around Confluent RBAC. The structure of the Hands-on is as followed
* Explaining and Introduce Role based Access Control
* Labs: Get to know the environment
* Advanced explanation of Role based Access Control: A real use case setup
* Advanced RBAC Labs to setup the real use case

In general, the hands-on will take 4 hours.
* Start at   10am: Intro and frist labs
* break at   12am: 1 hour break
* Continue at 1pm: Additional Labs
* Finish at   3pm

# Environment for Hands-on Workshop Labs
The Hands-on environment can be deployed in three ways 
1. run Docker-Compose on your own hardware/laptop [use docker-locally](rbac-docker/)
2. create the demo environment in Cloud Provider infrastructure, [deploy cloud environment](terraform/)
3. Confluent will deploy a cloud environment for you, and will send you the workshops all credentials

## Prerequisites for running environment in Cloud
For an environment in cloud you need to run following components on your machine: 
* Browser with internet access
* if you want to deploy in our own environment
  - create your own SSH key and deploy in AWS/Google, I use the key name `hackathon-temp-key`
  - terraform have to be installed
  - Terraform will install everything you need to execute during the workshop on clooud compute instance
* Having internet access and Port 80, 443, 22, 9021 have to be open

## Prerequisites for running environment on own hardware
For an environment on your hardware, you have to 
- Docker installed
- Java8 installed
- Confluent Platform 5.4 installed

## Optional
Install on your desktop Apache Directory Studio to create and modify LDAP users in openLDAP. [Download Apache Directory Studio](https://directory.apache.org/studio/downloads.html)
Apache Directory Studio is important if you want to add user/group in openLDAP or modify users or groups.
But wee offer the possibility to add user via ldapadd. So, Apache Directory is really optinal.

# Hands-on Workshop structur
Three days before the workshop we will send out to all attendees an email:
* Please be prepare
      - Watch Video Replay of RBAC as foundation for this Hands-on Workshop, see [here](https://events.confluent.io/kitchentour2020)
      - Your HW/SW have to be prepared before the workshop starts
* Ad we will ask you, if you run on your own environment or your would like to have an environment provisioned by Confluent.

## Hands-on Agenda and Labs:
0. We will start with a first enviroment check:
   Is everything up and running, and final question if Confluent should provision an environment for you.
   We expect 20 MIN time-slot

1. Intro Role based Access Control (PPT)         -   30 Min
        * RECAP Role based Access Control - short presentation by presenter (10 minites)
        * What is structure for today? (20 minutes)
        * In parallel all the environments for the attendees will be provisioned and attendees will all the credentials via email
2. LAB 1-2: Understand the environment and first labs -   60 Min                                               
        * Short intro and demo by presenter (10 Min)
        * Attendes doing Labs (50 Min)
          * Lab1: Check your environment
            - on your local machine, [Check your environment](labs/Lab1-localmachine.md/)
            - in cloud environment, [Check your environment](labs/Lab1-cloud.md)
          * Lab 2: Checking your lab environment
            - on your local machine, [goto Lab2-localmachine](labs/Lab2-localmachine.md)
            - in cloud , [goto to Lab2-cloud](labs/Lab2-cloud.md)
LUNCH Break                                         -     60 Minutes
3. Lab 3-4: RBAC real use case setuo                -    110 Minutes         
        * Short Introduction and demo by presenter (20 Min)
        * Attendess doing their labs (90 Min)
          * Lab 3. First Authorization check
            Execute the next Lab and check authorization: [Lab3](labs/Lab3.md)
          * Lab 4. High level Hands-on with RBAC: [Lab4](labs/Lab4.md)
4. Wrap-up and Finish                               -     15 Minutes

# Stop everything
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
```bash
# for running in cloud compute
confluent login --url http://localhost:8090
# for running on your local machine against cloud environment
confluent login --url http://pubip:8090
```
Set `KAFKA_CLUSTER_ID` in cloud compute it is already prepared for you.
You can get the Cluster ID as followed
```bash
ZK_HOST=publicip:2181
KAFKA_CLUSTER_ID=$(zookeeper-shell $ZK_HOST get /cluster/id 2> /dev/null | grep version | jq -r .id)
# or
confluent cluster describe --url http://localhost:8090
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

# Lab 3. First Authorization check
Create topic as user bender, first show configs property files:
Show client configs, which are prepared in aws compute:
```
cd /home/ec2-user/software/confluent-rbac-demo-master/rbac-docker/client-configs/
ls
cat professor.properties
cat bender.properties
```



Now, try to create a topic as user bender (should fail):
```
kafka-topics --bootstrap-server localhost:9094 --create --topic cmtest --partitions 1 --replication-factor 1 --command-config bender.properties
```
see error statement `[Authorization failed.]`

Try now as professor, he is the SuperUser:
```
kafka-topics --bootstrap-server localhost:9094 --create --topic cmtest --partitions 1 --replication-factor 1 --command-config professor.properties
kafka-topics --bootstrap-server localhost:9094 --list --command-config professor.properties
```

Try all the URLs as short demo :
  * go to control center as professor http://publicip:9021
  * logout try as Hermes, he is also SystemAdmin http://publicip :9021
  * He did not see CONNECT, KSQL and has no access to Schema Registry (Topic View)

Try Schema Registry
* as unauthoried user:
```
curl localhost:8081/subjects
```

* As Authroized User:
```
curl -u professor:professor localhost:8081/subjects
# Showed empty Schema
```

* try as anonymous user (is not configured):
```
curl -u ANONYMOUS localhost:8081/subjects
```

* and finally try as user frey
```
curl -u fry:fry localhost:8081/subjects
# Will show empty Schema
```

This was a short overview of configured RBAC environment.
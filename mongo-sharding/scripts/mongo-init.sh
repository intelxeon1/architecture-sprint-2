#!/bin/bash

###
# Инициализируем сервер конфигурации
docker compose exec -T configSrv mongosh <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF


# shard1
docker compose exec -T shard1-1 mongosh --port 27018 <<EOF
rs.initiate({_id : "shard1",members: [{ _id : 0, host : "shard1-1:27018" }] });
EOF


# shard2
docker compose exec -T shard2-1 mongosh --port 27018 <<EOF
rs.initiate({_id : "shard2", members: [{ _id : 0, host : "shard2-1:27018" }] });
EOF


# router
sleep 5s
docker compose exec -T router mongosh<<EOF
sh.addShard( "shard1/shard1-1:27018");
sh.addShard( "shard2/shard2-1:27018");
EOF
 

# add data
docker compose exec -T router mongosh <<EOF
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
EOF
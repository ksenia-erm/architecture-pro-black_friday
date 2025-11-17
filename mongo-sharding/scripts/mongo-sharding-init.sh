#!/bin/bash

echo "Init Config Server..."
docker compose exec -T mongo-config-srv mongosh --port 27117 --quiet <<MONGO
rs.initiate({
  _id: "mongo-config-srv",
  configsvr: true,
  members: [
    { _id: 0, host: "mongo-config-srv:27117" }
  ]
});
MONGO

echo "Init Shard 1..."
docker compose exec -T mongo-shard1 mongosh --port 27118 --quiet <<MONGO
rs.initiate({
  _id: "mongo-shard1",
  members: [
    { _id: 0, host: "mongo-shard1:27118" }
  ]
});
MONGO

echo "Init Shard 2..."
docker compose exec -T mongo-shard2 mongosh --port 27119 --quiet <<MONGO
rs.initiate({
  _id: "mongo-shard2",
  members: [
    { _id: 0, host: "mongo-shard2:27119" }
  ]
});
MONGO

echo "Await 10 sec..."
sleep 10

echo "Add shards to cluster..."
docker compose exec -T mongo-router mongosh --port 27120 --quiet <<MONGO
sh.addShard("mongo-shard1/mongo-shard1:27118");
sh.addShard("mongo-shard2/mongo-shard2:27119");
MONGO

echo "Enable sharding in db..."
docker compose exec -T mongo-router mongosh --port 27120 --quiet <<MONGO
sh.enableSharding("somedb");
MONGO

echo "Make shard collection helloDoc..."
docker compose exec -T mongo-router mongosh --port 27120 --quiet <<MONGO
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
MONGO

echo "Insert data..."
docker compose exec -T mongo-router mongosh --port 27120 --quiet <<MONGO
use somedb
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: "ly" + i});
}
MONGO

docker compose exec -T mongo-router mongosh --port 27120 --quiet <<MONGO
use somedb
print("Total records: " + db.helloDoc.countDocuments());
print("Get shard distribution...");
db.helloDoc.getShardDistribution();
MONGO

echo "END"

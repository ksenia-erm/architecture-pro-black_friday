#!/bin/bash

echo "Init Config Server..."
docker compose exec -T mongo-config-srv-repl mongosh --port 27117 --quiet <<MONGO
rs.initiate({
  _id: "mongo-config-srv-repl",
  configsvr: true,
  members: [
    { _id: 0, host: "mongo-config-srv-repl:27117" }
  ]
});
MONGO

echo "Init Shard 1..."
docker compose exec -T mongo-shard1-1 mongosh --port 27130 --quiet <<MONGO
rs.initiate({
  _id: "mongo-shard1-1",
  members: [
    { _id: 0, host: "mongo-shard1-1:27130" },
    { _id: 1, host: "mongo-shard1-2:27131" },
    { _id: 2, host: "mongo-shard1-3:27132" }
  ]
});
MONGO

until docker compose exec -T mongo-shard1-1 mongosh --port 27130 --quiet --eval "db.isMaster().ismaster" | grep true; do
  echo waiting for shard1-1...
  sleep 2;
done

echo "Init Shard 2..."
docker compose exec -T mongo-shard2-1 mongosh --port 27140 --quiet <<MONGO
rs.initiate({
  _id: "mongo-shard2-1",
  members: [
    { _id: 0, host: "mongo-shard2-1:27140" },
    { _id: 1, host: "mongo-shard2-2:27141" },
    { _id: 2, host: "mongo-shard2-3:27142" },
  ]
});
MONGO

until docker compose exec -T mongo-shard2-1 mongosh --port 27140 --quiet --eval "db.isMaster().ismaster" | grep true; do
  echo waiting for shard2-1...
  sleep 2;
done

echo "Add shards to cluster..."
docker compose exec -T mongo-router-repl mongosh --port 27120 --quiet <<MONGO
sh.addShard("mongo-shard1-1/mongo-shard1-1:27130,mongo-shard1-2:27131,mongo-shard1-3:27132");
sh.addShard("mongo-shard2-1/mongo-shard2-1:27140,mongo-shard2-2:27141,mongo-shard2-3:27142");
MONGO

echo "Enable sharding in db..."
docker compose exec -T mongo-router-repl mongosh --port 27120 --quiet <<MONGO
sh.enableSharding("somedb");
MONGO

echo "Make shard collection helloDoc..."
docker compose exec -T mongo-router-repl mongosh --port 27120 --quiet <<MONGO
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
MONGO

echo "Insert data..."
docker compose exec -T mongo-router-repl mongosh --port 27120 --quiet <<MONGO
use somedb
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: "ly" + i});
}
MONGO

docker compose exec -T mongo-router-repl mongosh --port 27120 --quiet <<MONGO
use somedb
print("Total records: " + db.helloDoc.countDocuments());
print("Get shard distribution...");
db.helloDoc.getShardDistribution();
MONGO

echo "END"

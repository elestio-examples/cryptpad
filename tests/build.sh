#!/usr/bin/env bash

chmod +x ./docker-entrypoint.sh
chmod +x ./supervisord.conf

mkdir -p ./data
mkdir -p ./data/blob
mkdir -p ./data/block
mkdir -p ./data/data
mkdir -p ./data/data/logs
mkdir -p ./data/files
mkdir -p ./customize

chown -R 4001:4001 ./data
chown -R 4001:4001 ./customize
chown -R 4001:4001 ./config.js

docker buildx build . --output type=docker,name=elestio4test/cryptpad:latest | docker load
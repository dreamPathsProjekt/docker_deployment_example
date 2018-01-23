#!/bin/bash

chmod a+x ./docker-entry.sh && \
docker build -t mariadb . && \
docker tag mariadb  registry.dream:5001/mariadb:$1 && \
docker tag mariadb  registry.dream:5001/mariadb:latest && \
docker push registry.dream:5001/mariadb:$1 && \
docker push registry.dream:5001/mariadb:latest

exit 0
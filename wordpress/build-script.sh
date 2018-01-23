#!/bin/bash

chmod a+x ./docker-entry.sh && \
docker build -t wordpress . && \
docker tag wordpress  registry.dream:5001/wordpress:$1 && \
docker tag wordpress  registry.dream:5001/wordpress:latest && \
docker push registry.dream:5001/wordpress:$1 && \
docker push registry.dream:5001/wordpress:latest

exit 0
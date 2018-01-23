#!/bin/bash

chmod a+x ./docker-entry.sh && \
docker build -t pma . && \
docker tag pma  registry.dream:5001/pma:$1 && \
docker tag pma  registry.dream:5001/pma:latest && \
docker push registry.dream:5001/pma:$1 && \
docker push registry.dream:5001/pma:latest

exit 0
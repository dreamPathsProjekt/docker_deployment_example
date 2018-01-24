#!/bin/bash

chmod a+x ./docker-entry.sh && \
docker build -t caddybeta . && \
docker tag caddybeta registry.greece:5001/caddybeta:$1 && \
docker tag caddybeta registry.greece:5001/caddybeta:latest && \
docker push registry.greece:5001/caddybeta:$1 && \
docker push registry.greece:5001/caddybeta:latest

exit 0

#!/bin/bash

chmod a+x `pwd`/docker-exporter/docker-entry.sh && \
docker build -t docker-exporter `pwd`/docker-exporter/. && \
docker tag docker-exporter registry.dream:5001/docker-exporter:$1 && \
docker tag docker-exporter registry.dream:5001/docker-exporter:latest && \
docker push registry.dream:5001/docker-exporter:$1 && \
docker push registry.dream:5001/docker-exporter:latest

exit 0

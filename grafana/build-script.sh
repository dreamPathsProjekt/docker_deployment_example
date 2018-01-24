#!/bin/bash

chmod a+x `pwd`/grafana/docker-entry.sh && \
docker build -t grafana `pwd`/grafana/. && \
docker tag grafana registry.dream:5001/grafana:$1 && \
docker tag grafana registry.dream:5001/grafana:latest && \
docker push registry.dream:5001/grafana:$1 && \
docker push registry.dream:5001/grafana:latest

exit 0

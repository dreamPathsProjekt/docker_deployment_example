#!/bin/bash

chmod a+x `pwd`/caddy_monitoring/docker-entry.sh && \
docker build -t caddy_monitoring `pwd`/caddy_monitoring/. && \
docker tag caddy_monitoring registry.dream:5001/caddy_monitoring:$1 && \
docker tag caddy_monitoring registry.dream:5001/caddy_monitoring:latest && \
docker push registry.dream:5001/caddy_monitoring:$1 && \
docker push registry.dream:5001/caddy_monitoring:latest

exit 0

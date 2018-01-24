#!/bin/bash

chmod a+x `pwd`/caddy/docker-entry.sh && \
docker build -t caddy `pwd`/caddy/. && \
docker tag caddy registry.dream:5001/caddy:$1 && \
docker tag caddy registry.dream:5001/caddy:latest && \
docker push registry.dream:5001/caddy:$1 && \
docker push registry.dream:5001/caddy:latest

exit 0

#!/bin/bash

chmod a+x `pwd`/blackbox/docker-entry.sh && \
docker build -t blackbox `pwd`/blackbox/. && \
docker tag blackbox registry.dream:5001/blackbox:$1 && \
docker tag blackbox registry.dream:5001/blackbox:latest && \
docker push registry.dream:5001/blackbox:$1 && \
docker push registry.dream:5001/blackbox:latest

exit 0

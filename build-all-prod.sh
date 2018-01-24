#!/bin/bash

# apply version for Caddy as an argument, e.g. build-all.sh 0.5

chmod a+x `pwd`/caddy/build-script.sh && \
`pwd`/caddy/build-script.sh $1

chmod a+x `pwd`/caddy_monitoring/build-script.sh && \
`pwd`/caddy_monitoring/build-script.sh $1

chmod a+x `pwd`/docker-exporter/build-script.sh && \
`pwd`/docker-exporter/build-script.sh $1

chmod a+x `pwd`/grafana/build-script.sh && \
`pwd`/grafana/build-script.sh $1

chmod a+x `pwd`/blackbox-exporter/build-script.sh && \
`pwd`/blackbox-exporter/build-script.sh $1

# echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
# echo "The present working directory is `pwd`"

# docker stack deploy --compose-file ./development/wp_mariadb_admin.yml wp

exit 0

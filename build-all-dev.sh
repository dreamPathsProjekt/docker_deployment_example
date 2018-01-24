#!/bin/bash

# apply version for Caddy as an argument, e.g. build-all.sh 0.5

chmod a+x `pwd`/caddy/build-script.sh && \
`pwd`/caddy/build-script.sh $1

# echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
# echo "The present working directory is `pwd`"

# docker stack deploy --compose-file ./development/wp_mariadb_admin.yml wp

exit 0

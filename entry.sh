#!/bin/bash

chmod a+x ./caddy/build-script.sh && \
./caddy/build-script.sh $1 && \
docker stack deploy --compose-file ./development/wp_mariadb_admin.yml wp

exit 0
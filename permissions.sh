#!/bin/bash

chmod a+x ./caddy/build-script.sh && \
chmod a+x ./wordpress/build-script.sh && \
chmod a+x ./mariadb/build-script.sh && \
chmod a+x ./pma/build-script.sh && \

# docker stack deploy --compose-file ./development/wp_mariadb_admin.yml wp

exit 0
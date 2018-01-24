#!/bin/bash

chmod a+x `pwd`/caddy/build-script.sh && \
`pwd`/caddy/build-script.sh $1
# chmod a+x ./wordpress/build-script.sh && \
# chmod a+x ./mariadb/build-script.sh && \
# chmod a+x ./pma/build-script.sh && \

#cd ./caddy && \
#./build-script $1 && \
#cd ../

# echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
# echo "The present working directory is `pwd`"

# docker stack deploy --compose-file ./development/wp_mariadb_admin.yml wp

exit 0

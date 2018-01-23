#!/bin/bash

export WORDPRESS_DB_PASSWORD=$(cat /run/secrets/wp_db_pass)

set -- /usr/local/bin/docker-entrypoint.sh "$@"
exec "$@"
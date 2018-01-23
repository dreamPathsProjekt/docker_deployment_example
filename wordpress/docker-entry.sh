#!/bin/bash

export WORDPRESS_DB_PASSWORD_FILE=$(cat /run/secrets/wp_db_pass)

set -- /usr/local/bin/docker-entrypoint.sh "$@"
exec "$@"
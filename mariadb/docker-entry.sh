#!/bin/bash

export MYSQL_PASSWORD_FILE=$(cat /run/secrets/wp_db_pass)
export MYSQL_ROOT_PASSWORD_FILE=$( /run/secrets/db_root_pass)

exec /usr/local/bin/docker-entrypoint.sh
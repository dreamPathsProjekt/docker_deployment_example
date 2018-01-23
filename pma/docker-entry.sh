#!/bin/bash

export PMA_USER=$(cat /run/secrets/pma_user)
export PMA_PASSWORD=$(cat /run/secrets/pma_pass)
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_pass)

exec /run.sh
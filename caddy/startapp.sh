#!/bin/sh -e

export ADMIN_USER=$(cat /run/secrets/lb_admin_user)
export ADMIN_PASSWORD=$(cat /run/secrets/lb_admin_pass)

set -- /sbin/tini "$@"

exec "$@"
#!/bin/bash

config_file=/etc/grafana/grafana.ini

value_to_change=xxx

function set_config() {
	# escape invalid characters
	# for escape options, check this link http://www.linuxquestions.org/questions/programming-9/passing-variables-which-contain-special-characters-to-sed-4175412508/
	escaped="$2"

	# escape all backslashes first
	escaped="${escaped//\\/\\\\}"

	# escape slashes
	escaped="${escaped//\//\\/}"	
		
	# finally make the replacement
	sed -i "s/^\($1\s*=\s*\).*\$/\1$escaped/" $3
}

function set_config_target() {
        #escape invalid characters
        #for escape options, check this link http://www.linuxquestions.org/questions/programming-9/passing-variables-which-contain-special-characters-to-sed-4175412508/
        escaped="$3"

	#escape all backslashes first
	escaped="${escaped//\\/\\\\}"

        #escape slashes
        escaped="${escaped//\//\\/}"
        #finally make the replacement
        sed -ri "s/^(\s*)($1\s*:\s*$2\s*$)/\1$1: $escaped/" $4
}

ADMIN_USER=$(cat /run/secrets/lb_admin_user)
if [ ! -z "$ADMIN_USER" ]; then
        set_config "admin_user " $ADMIN_USER $config_file
fi

ADMIN_PASSWORD=$(cat /run/secrets/lb_admin_pass)
if [ ! -z "$ADMIN_PASSWORD" ]; then
        set_config "admin_password " $ADMIN_PASSWORD $config_file
fi

if [ ! -z "$DOMAIN" ]; then
        set_config "domain " $DOMAIN $config_file
fi

exec /run.sh


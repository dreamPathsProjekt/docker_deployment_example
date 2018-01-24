#!/bin/sh -e

config_file=/etc/blackbox_exporter/config.yml

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

if [ ! -z "$INSECURE_SKIP_VERIFY" ]; then
        set_config_target "insecure_skip_verify" $value_to_change $INSECURE_SKIP_VERIFY $config_file
fi

set -- /bin/blackbox_exporter "$@"

exec "$@"

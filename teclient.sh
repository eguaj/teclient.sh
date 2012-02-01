#!/bin/bash

set -e

function usage {
	echo
	echo "  export TE_HOST=<te_host_ip_addr>"
	echo "  export TE_PORT=<te_port_number>"
	echo
	echo "  $0 convert <file_pathname> [<conversion_name> [<input_file_mime>]]"
	echo "  $0 info|get|abort <id>"
	echo
}

function te_convert {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	FILE=$1
	SIZE=$(stat -c %s "$FILE" 2> /dev/null || gstat -c %s "$FILE" 2> /dev/null)
	FNAME=$(basename "$FILE")
	CONVERT_TO="utf8"
	if [ -n "$2" ]; then
		CONVERT_TO=$2
	fi
	MIME="text"
	if [ -n "$3" ]; then
		MIME=$3
	fi

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	read LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "CONVERT" 1>&3
	echo "name=\"$CONVERT_TO\" fkey=\"$FKEY\" size=\"$SIZE\" fname=\"$FNAME\" mime=\"$MIME\"" 1>&3
	cat "$FILE" 1>&3
	RESPONSE=$(head -1 0<&3)
	if [ "${RESPONSE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$RESPONSE]]]" 1>&2
		exit 11
	fi
	TID=$(sed -n -e 's:.*<task[^>][^>]*id="\([0-9][0-9]*\)".*:\1:p' <<EOF
$RESPONSE
EOF)
	if [ -z "$TID" ]; then
		echo "Could not get tid from response [[[$RESPONSE]]]" 1>&2
		exit 12
	fi
	echo "$TID"
}

function te_info {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	read LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "INFO" 1>&3
	echo "  id=\"$ID\"" 1>&3
	RESPONSE=$(head -1 0<&3)
	echo "$RESPONSE"
}

function te_abort {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	read LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "ABORT" 1>&3
	echo "  id=\"$ID\"" 1>&3
	RESPONSE=$(head -1 0<&3)
	if [ "${RESPONSE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$RESPONSE]]]" 1>&2
		exit 11
	fi
}

function te_get {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	read LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "GET" 1>&3
	echo "  id=\"$ID\"" 1>&3
	RESPONSE=$(head -1 0<&3)
	if [ "${RESPONSE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$RESPONSE]]]" 1>&2
		exit 11
	fi
	SIZE=$(sed -n -e 's:.*<task[^>][^>]*size="\([0-9][0-9]*\)">.*:\1:p' <<EOF
$RESPONSE
EOF)
	if [ -z "$SIZE" ]; then
		echo "Could not get size from response [[[$RESPONSE]]]" 1>&2
		exit 12
	fi
	head -c "$SIZE" 0<&3
}

if [ -z "$TE_HOST" -o -z "$TE_PORT" ]; then
	usage
	exit 1
fi

if [ -z "$1" ]; then
	usage
	exit 1
fi

OP=$1
shift
case $OP in
	convert)
		te_convert "$@"
		;;
	info)
		te_info "$@"
		;;
	abort)
		te_abort "$@"
		;;
	get)
		te_get "$@"
		;;
	*)
		usage
		exit 1
		;;
esac

exit 0

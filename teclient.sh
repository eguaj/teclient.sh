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

function get_response {
	(
		cat 0<&3 | (
			read LINE;
			if [ "$LINE" != "Continue" ]; then
				echo "Not a TE server?" 1>&2
				exit
			fi
			head -1 1>&2
			cat
		) &
		cat 1>&3
	) 3<> "/dev/tcp/$TE_HOST/$TE_PORT"
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
	(
	echo "CONVERT"
	echo "name=\"$CONVERT_TO\" fkey=\"$FKEY\" size=\"$SIZE\" fname=\"$FNAME\" mime=\"$MIME\""
	cat "$FILE"
	) | get_response
}

function te_info {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	(
	echo "INFO"
	echo "  id=\"$ID\""
	) | get_response
}

function te_abort {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	(
	echo "ABORT"
	echo "  id=\"$ID\""
	) | get_response
}

function te_get {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	(
	echo "GET"
	echo "  id=\"$ID\""
	) | get_response
}

function te_status {
	(
	echo "STATUS"
	) | get_response
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
	status)
		te_status "$@"
		;;
	*)
		usage
		exit 1
		;;
esac

exit 0

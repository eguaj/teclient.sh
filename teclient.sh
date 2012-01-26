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
	(
	echo "CONVERT"
	echo "name=\"$CONVERT_TO\" fkey=\"$FKEY\" size=\"$SIZE\" fname=\"$FNAME\" mime=\"$MIME\""
	cat "$FILE"
	) >&3
	cat <&3
	echo
}

function te_info {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"
	(
	echo "INFO"
	echo "  id=\"$ID\""
	) >&3
	cat <&3
	echo
}

function te_abort {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"
	(
	echo "ABORT"
	echo "  id=\"$ID\""
	) >&3
	cat <&3
	echo
}

function te_get {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	ID=$1
	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"
	(
	echo "GET"
	echo "  id=\"$ID\""
	) >&3
	cat <&3
	echo
}

function te_status {
	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"
	(
	echo "STATUS"
	) >&3
	cat <&3
	echo
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

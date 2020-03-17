#!/bin/bash

set -e

function usage {
	echo
	echo "  export TE_HOST=<te_host_ip_addr>"
	echo "  export TE_PORT=<te_port_number>"
	echo
	echo "  $0 convert <file_pathname> [<conversion_name> [<input_file_mime>]]"
	echo "  $0 info|get|abort <id>"
	echo "  $0 info:engines"
	echo "  $0 check"
	echo
}

function te_convert {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	local FILE=$1
	local SIZE=$(stat -c %s "$FILE" 2> /dev/null || gstat -c %s "$FILE" 2> /dev/null)
	local FNAME=$(basename "$FILE")
	local CONVERT_TO="utf8"
	if [ -n "$2" ]; then
		CONVERT_TO=$2
	fi
	local MIME="$3"
	if [ -z "$MIME" ]; then
		MIME=$(file -bi "$FILE" | cut -d';' -f1)
	fi
	if [ -z "$MIME" ]; then
		MIME="text"
	fi

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	local LINE
	read -t 5 LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "CONVERT" 1>&3
	echo "name=\"$CONVERT_TO\" fkey=\"$FKEY\" size=\"$SIZE\" fname=\"$FNAME\" mime=\"$MIME\"" 1>&3
	cat "$FILE" 1>&3
	read -t 5 LINE 0<&3
	if [ "${LINE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$LINE]]]" 1>&2
		exit 11
	fi
	local TID=$(echo "$LINE" | sed -n -e 's:.*<task[^>][^>]*id="\([^"][^"]*\)".*:\1:p')
	if [ -z "$TID" ]; then
		echo "Could not get tid from response [[[$LINE]]]" 1>&2
		exit 12
	fi
	echo "$TID"
}

function te_info {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	local ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	local LINE
	read -t 5 LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "INFO" 1>&3
	echo "  id=\"$ID\"" 1>&3
	read -t 5 LINE 0<&3
	echo "$LINE"
}

function te_abort {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	local ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	local LINE
	read -t 5 LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "ABORT" 1>&3
	echo "  id=\"$ID\"" 1>&3
	read -t 5 LINE 0<&3
	if [ "${LINE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$LINE]]]" 1>&2
		exit 11
	fi
}

function te_get {
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	local ID=$1

	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	local LINE
	read -t 5 LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "GET" 1>&3
	echo "  id=\"$ID\"" 1>&3
	read -t 5 LINE 0<&3
	if [ "${LINE:0:22}" != "<response status=\"OK\">" ]; then
		echo "Error response [[[$LINE]]]" 1>&2
		exit 11
	fi
	local SIZE=$(echo "$LINE" | sed -n -e 's:.*<task[^>][^>]*size="\([0-9][0-9]*\)">.*:\1:p')
	if [ -z "$SIZE" ]; then
		echo "Could not get size from response [[[$LINE]]]" 1>&2
		exit 12
	fi
	head -c "$SIZE" 0<&3
}

function helloworld_pdf {
	uudecode -o - <<'EOF' | gzip -dc
begin-base64 644 helloworld.pdf
H4sIAOvdl1AAA+1W3WoTQRQuXhQZLwUvvJDpRWmDtPOzO/sjpZBmEwy2tiRFK0kutruTZCTdDbtT
bfsA3nsrvoA3vorQN5DqQ/RC8Gx20w1NURARhIaEzHznnPm+OTOcM8t7XmONrVto+dvFl3PEMMXx
4WvUIYCT5pE/kFv5Xy3/a5J9eaJ7SEZh5mcW/hsbZFtGAz3EApAWIg010jIhjZGvpSeDOJRocxOl
OpH+ETr5mKKv52+NPWq27jYv7rzf7DYW0YN3i2ip0n346JPrXqLvl3W3cvZh6VX381J34f7CvR8Z
Z7FAwS4KdmFOEbvUs5fEQVtqzApBcaQBbVBsTQBQA98izCnDakCg4wSvatgnH4f9CiL7So8kXq3F
0RuZaBnizAb4xFfFkQebxKveE04ZZ4wKZpmU248pW6F0BfxASngcSFgUsjpSh3hbQYC9TtcF7q7u
+AHebeODbqUyI8kqJe2fjuVEPyLt40OdzTKIIbLlpzIzkFp8nCiZ5Nv0ZBokapztwp2eRpLq2tBP
MEVk2y/GXAhEXqpQD9OORSExf/5Dt/G38bfx/218D5F6BFVaRQPM6LRAFqVoAszWoqlrXoCmMygl
UTVKVWn1VL8vExkFMu1Qsh7FOpR9ND9g3CnHxq88/9aAmXxmLP4BY0knnBus6dgPJGK2QYan46GM
UG/mANwbekFZ5FHWZQcpNqCaV9NARhpb3Ibu5I+fSjUYaixsAw5D5rY1I5tlS2xtxSedNWHhNS7g
FtgOdoTdy23P/SNZdpWm9kcqqEYDaIPQQdpaHr2Ae+IiclBQmMBeCjauCd6DlwO0QT/JBPC8J0E3
1TBNsZnPWzIFOrgq2M6BHRkqP5OYXT/hCuyYfDYr/AaSNFv3GEigOT5TYdrBmZRWb+Yys2thNR82
Fw9QHl+oK/1PEjgeihlH9OqDLSEMgfv4CmPwFJlYoinGuTGPMcO8jlFqGXMYc9w5zKTzGKf2PGbx
6xhzxZwfE/acH+ezvDrx1QhOHxLVVmcySwFpxTHktnhSNaN+jJ1i7HU2qnbVsB14/Jjc8Syv6rpO
ndkOULmex0R98/cevfyV6Cd6knduGDZaXq7vNtBPT+N6qqkKAAA=
====
EOF
}

function te_check {
	local FILE=$(mktemp teclient.XXXXXX)
	helloworld_pdf > "$FILE"
	echo "Sending sample PDF to TXT conversion..."
	local TID=$(te_convert "$FILE" utf8 application/pdf)
	rm "$FILE"
	echo "Waiting for 15 seconds..."
	sleep 15
	echo "Fetching result..."
	te_info "$TID"
	local RESPONSE=$(te_get "$TID" | tr "\n" "%" | sed -e 's/%//')
	if [ "[${RESPONSE:0:12}]" != "[Hello world.]" ]; then
		echo "Unexpected response [[[$RESPONSE]]] for tid '$TID'." 1>&2
		exit 13
	fi
	echo "Ok, got expected response."
	echo "Cleanup..."
	te_abort "$TID"
	echo "Done."
}

function te_info_engines {
	exec 3<> "/dev/tcp/$TE_HOST/$TE_PORT"

	local LINE
	read -t 5 LINE 0<&3
	if [ "$LINE" != "Continue" ]; then
		echo "Not a TE server?" 1>&2
		exit 10
	fi
	echo "INFO:ENGINES" 1>&3
	read -t 5 LINE 0<&3
	if [ "${LINE:0:22}" != "<response status=\"OK\" " ]; then
		echo "Error response [[[$LINE]]]" 1>&2
		exit 11
	fi
	local SIZE=$(echo "$LINE" | sed -n -e 's:.*[[:space:]]size="\([0-9][0-9]*\)".*:\1:p')
	if [ -z "$SIZE" ]; then
		echo "Could not get size from response [[[$LINE]]]" 1>&2
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
	check)
		te_check "$@"
		;;
	info:engines)
		te_info_engines "$@"
		;;
	*)
		usage
		exit 1
		;;
esac

exit 0

#!/bin/bash
# $Id: check_ssl_cert.sh 188 2011-11-28 20:20:25Z thomas.merkel $

dir="/etc/ssl"
now="$(date +%s)"
expired=""
int1=""
int2=""
dir=""
warn=864000
crit=2592000

while [ $# -gt 0 ]; do
	case "${1}" in
		"-w" | "--warn" )
			warn=${2}
			shift 1
		;;
		"-c" | "--critical" )
			crit=${2}
			shift 1
		;;
		"-d" | "--directory" )
			dir="$dir ${2}"
			shift 1
		;;
		"-e" | "--extension" )
			ext="${2}"
			shift 1
		;;
		"-h" | "--help" )
			echo "$0 -w|--warn <seconds> -c|--critical <seconds> -d|--directory <directory>"
			exit 0
		;;
	esac
	shift 1
done

if [ "$dir" == "" ]; then
	dir="/etc/ssl"
fi

for x in $(find $dir -type f -regex ".*\(crt\|pem\)" -not -name "ca-certificates.crt" 2> /dev/null); do
	enddate="$(openssl x509 -in $x -noout -enddate 2>/dev/null)"
	if [ "$?" == "0" ]; then
		name="$(basename $x)"
		certificate="$(LC_ALL=C date +%s --date "$(echo $enddate | sed -e 's/notAfter=//')" 2>/dev/null)"
		if [ "$?" == "0" ]; then
			diff="$(expr $certificate - $now)"
			days="$(expr $diff / 86400)"
			hours="$(expr $diff % 86400 / 3600)"
			
			if [ $diff -lt 0 ]; then
				expired="${expired}${name},"
				continue
			fi
			if [ $diff -lt ${warn} ]; then
				int1="${int1}${name} (in $days day(s) $hours hour(s)),"
				continue
			fi
			if [ $diff -lt ${crit} ]; then
				int2="${int2}${name} (in $days day(s) $hours hour(s)),"
			fi
		fi
	fi
done

# check for files/dirs which cannot be read
noread=""
for x in $(find $dir ! -perm -a+r -regex ".*\(crt\|pem\)" -not -name "ca-certificates.crt" 2>/dev/null); do
	noread="${noread}$x,"
done

test -z "$noread" || noread="Unable to read the following certs:${noread%%,}"

# check for dirs which cannot be read
for x in $(find $dir -type d ! -perm -a+r 2>/dev/null); do
	noread="${noread}$x,"
done

test -z "$noread" || noread="Cannot read contents of the following directories:${noread%%,}"

## process
if [ "$expired" != "" ]; then
	msg="CRITICAL - EXPIRED certificate \"${expired%%,}\". ${noread}"
	exitcode=2
fi

if [ "$int1" != "" ]; then
	test -z "$msg" || msg="$msg ;"
	msg="$msg WARNING - Expiring certificate \"${int1%%,}\". ${noread}"
	exitcode=1
fi

if [ "$int2" != "" ]; then
	test -z "$msg" || msg="$msg ;"
	msg="$msg OK - Expiring certificate \"${int2%%,}\"."
	if test ! -z "$noread"; then
		msg="UNKNOWN - Expiring certificate \"${int2%%,}\". ${noread}"
		exitcode=3
	else
		exitcode=0
	fi
fi

if [ "$msg" == "" ]; then
	msg="OK - Certificates are OK."
	if test ! -z "$noread"; then
		msg="UNKNOWN - ${noread}"
		exitcode=3
	else
		exitcode=0
	fi
fi

echo $msg
exit $exitcode

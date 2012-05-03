#!/bin/bash
# $Id: header.avira 13 2008-04-15 15:13:02Z gweiss $

# Nagios check script to check whether a given interface has a given IP address
# Created by Wolfram Schlich <wschlich@gentoo.org>
# Extended by Georg Weiss <georg.weiss@avira.com>
# Licensed under the GNU GPLv2 or later
#
# External dependencies:
# - ip
# - egrep

##
## nagios state specific exit codes
##

declare -i state_ok=0
declare -i state_warning=1
declare -i state_critical=2
declare -i state_unknown=3
declare -i state_dependent=4

##
## functions
##

function usage() {
	echo
	echo "Usage: ${0##*/} <interface> -i <ipaddr-with-subnet-mask> -i <ipaddr-with-subnet-mask> ..."
	echo
}

function checkargs() {
	if [[ -z "${iface}" ]]; then
		usage
		exit ${state_unknown}
	fi
}

##
## main()
##

if [ "$UID" != "0" ]; then
	echo "i need to be executed with root priviledges."
	exit ${state_unknown}
fi

if [[ ! -x "$(type -p ip 2>/dev/null)" ]]; then
	echo "'ip' not executable"
	exit ${state_unknown}
fi

if [[ ! -x "$(type -p egrep 2>/dev/null)" ]]; then
	echo "'egrep' not executable"
	exit ${state_unknown}
fi

iface="${1}"; shift
index=0
while (( "$#" )); do
	case "${1}" in
		"-i" | "--interface" )
			ipaddr[$index]="${2}"
			let "index = $index + 1"
			shift 1
		;;
	esac
	shift 1
done
ips=$index
checkargs

if ! ip link show dev ${iface} >&/dev/null; then
	echo "CRITICAL - interface '${iface}' does NOT EXIST!"
	exit ${state_critical}
fi

# do not check link state if interface is a vlan interface
test ! -r /proc/net/vlan/${iface} && {
	if ! ip link show dev ${iface} 2>/dev/null | egrep "[[:space:]]${iface}:.*(,|<)UP(,|>)" >&/dev/null; then
		echo "CRITICAL - interface '${iface}' is DOWN!"
		exit ${state_critical}
	fi
	RX_errors="$(cat /proc/net/dev | grep ${iface}: | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s [:space:] | cut -d" " -f 5)"
	RX_drops="$(cat /proc/net/dev | grep ${iface}: | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s [:space:] | cut -d" " -f 6)"
	TX_errors="$(cat /proc/net/dev | grep ${iface}: | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s [:space:] | cut -d" " -f 11)"
	TX_drops="$(cat /proc/net/dev | grep ${iface}: | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s [:space:] | cut -d" " -f 12)"
	collisions="$(cat /proc/net/dev | grep ${iface}: | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s [:space:] | cut -d" " -f 14)"
	if [[ "${RX_errors}" != "0" || "${RX_drops}" != "0" || "${TX_errors}" != "0" || "${TX_drops}" != "0" || "${collisions}" != "0" ]]; then
		echo "CRITICAL - interface '${iface}' has ($RX_errors) RX-ERRORS,($RX_drops) RX-DROPS, ($TX_errors) TX-ERRORS, ($TX_drops) TX-DROPS, ($collisions) COLLISIONS! Check network (interface)!"
		exit ${state_critical}
	fi
}

msg=""
index=0
while [ "$index" -lt "$ips" ]
do
		ip=${ipaddr[$index]}
		let "index = $index + 1"
	if ! ip addr show dev ${iface} 2>/dev/null | egrep "inet6?[[:space:]]${ip}[[:space:]]" >&/dev/null; then
		if [ "$msg" == "" ]; then
			msg="interface '${iface}' does not have IP address(es) ${ip}"
		else 
			msg="$msg, ${ip}"
		fi
	fi
done

if [ "$msg" == "" ]; then
	echo "OK - interface '${iface}' has all IP addresses configured properly"
	exit ${state_ok}
else
	echo "CRITICAL - $msg configured!"
	exit ${state_critical}
fi

# vim:nu:ai:sw=4:ts=4:

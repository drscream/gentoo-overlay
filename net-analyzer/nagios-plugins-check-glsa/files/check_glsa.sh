#!/bin/bash
# $Id: check_glsa.sh 8 2008-07-30 09:33:09Z georg.weiss $
# vim:nu:ai:sw=4:ts=4:
#
# Nagios check script for GLSAs (Gentoo Linux Security Advisories)
# Created by Wolfram Schlich <wschlich@gentoo.org>
# Altered by Georg Weiss <georg@georgweiss.de>
# Licensed under the GNU GPLv2 or later
#
# External dependencies:
# - glsa-check from gentoolkit
# - sed
#

##
## nagios state specific exit codes
##

declare -i state_ok=0
declare -i state_warning=1
declare -i state_critical=2
declare -i state_unknown=3
declare -i state_dependent=4

##
## settings
##

declare -i msg_cut=150

##
## functions
##

function usage() {
        echo
        echo "Usage: ${0##*/}"
        echo
        echo " CRIT when the amount of GLSAs affecting the system is >= 1"
        echo
}

##
## main()
##

if [[ ! -x "$(type -p glsa-check 2>/dev/null)" ]]; then
        echo "'glsa-check' not executable"
        exit ${state_unknown}
fi

if [[ ! -x "$(type -p sed 2>/dev/null)" ]]; then
        echo "'sed' not executable"
        exit ${state_unknown}
fi

glsa_aff_str=$(glsa-check -t all 2>/dev/null | xargs glsa-check -p 2>/dev/null | sed -n -e 's#^.*[[:space:]]\(.*\)/\(.*\)-\([0-9].*\).*#\1/\2-\3 #p' | tr "\n" " "; if [ "${PIPESTATUS[0]}" == "1" ]; then echo "glsa-check failed"; fi)

if [ "${glsa_aff_str}" != "" ]; then
        msg="CRITICAL - affecting GLSAs: ${glsa_aff_str}"
        if [[ ${#msg} -ge ${msg_cut} ]]; then
                echo "${msg:0:${msg_cut}}[...]"
        else
                echo "${msg}"
        fi
        exit ${state_critical}
else
        echo "OK - system not affected by any GLSAs"
        exit ${state_ok}
fi

## should never reach this
exit ${state_unknown}

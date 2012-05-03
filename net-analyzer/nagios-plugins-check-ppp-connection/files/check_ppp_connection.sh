# $Id: check_ppp_connection.sh 118 2009-03-19 11:51:21Z georg.weiss $

iface="ppp0"
crit=5
warn=2

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
        "-i" | "--interface" )
            iface="${2}"
            shift 1
        ;;
        "-h" | "--help" )
            echo "$0 -w|--warn <seconds> -c|--critical <seconds> -i|--interface <pppX>"
            exit 0
        ;;
    esac
    shift 1
done

ppp_log="/var/log/syslog-ng/pppd.log"
ppp_log_yesterday="/var/log/syslog-ng.archive/pppd.log-$(date -d 'yesterday' +%Y%m%d).gz"

today=$(grep "Connect: $iface" ${ppp_log} | wc -l)
yesterday=$(zgrep "Connect: $iface" ${ppp_log_yesterday} | wc -l)
last=$(grep "Connect: $iface" ${ppp_log} | tail -n 1 | cut -d";" -f1)

msg="OK - today's last cut @ $last"

exitcode=0

if [ "$today" -gt "$warn" ]; then
	msg="WARNING - $today cuts today - today's last cut @ $last"
	exitcode=1
fi

if [ "$today" -gt "$crit" ]; then
	msg="CRITICAL - $today cuts today - today's last cut @ $last"
	exitcode=2
fi

if [ "$yesterday" -gt "$warn" ]; then
	msg="$msg - cuts yesterday $yesterday"
fi

echo $msg
exit $exitcode

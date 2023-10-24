#!/bin/sh

. /lib/ebee_funcs

IFPLUGD_ARGS="-i eth0 -m ethtool -l -f -I -u0 -d1 -r /etc/ifplugd/ifplugd.action"

start_eth0()
{
	pid=$(ps | awk '/ifplugd.*-i eth0/ && ! /grep/ {print $1}')
	if [ -z "$pid" ]
	then
		logger -s "Starting ifplugd for eth0"
		/usr/sbin/ifplugd $IFPLUGD_ARGS
	fi
}

stop_eth0()
{
	pid=$(ps | awk '/ifplugd.*-i eth0/ && ! /grep/ {print $1}')
	if [ -n "$pid" ]
	then
		logger -s "Stopping ifplugd for eth0"
		kill $pid 2>/dev/null
	fi
}

case "$1" in
    start)
		start_eth0
		;;
    stop)
		stop_eth0
		;;
    restart|reload)
        stop_eth0
        start_eth0
        ;;

esac

exit 0



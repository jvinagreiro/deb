#!/bin/sh

. /lib/ebee_funcs

# Run logrotate every two minutes

trap '' HUP INT QUIT TERM USR1 USR2

while :
do
	rm -f /var/lib/logrotate.status
	/usr/sbin/logrotate /etc/logrotate.conf
	sleep 120
done


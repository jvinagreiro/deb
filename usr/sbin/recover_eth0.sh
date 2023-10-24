#!/bin/sh
#
# Could someone please add a comment what this is meant for?


# On CC613 the GPIO used below is the weld check input, so don't touch it!

if grep -q '^CC613' /dev/ebee_variant
then
	exit
fi

# Bail out unless this is running on a Mennekes board

if ! grep -qi mennekes /home/charge/persistency/ChargePointVendor_ocpp
then
	exit
fi

stop=0
trap "stop=1" HUP

while true
do
	sleep 10

	# If 'stop' is non-zero we got a SIGHUP signal, probably from
	# mdev.action.charge

	if [ $stop -gt 0 ]
	then
		logger "recover_eth0.sh: stop was triggered from mdev"
		exit
	fi

    # Test if eth0 exists, in that case there's nothing to do

	if ifconfig eth0
	then
		logger "recover_eth0.sh: eth0 interface exists"
		exit
	fi

	# Also bail out if eth0 vanished but instead a block device appeared

	if [ -d /proc/scsi/usb-storage ]
	then
		logger "recover_eth0.sh: block device detected - stopping"
		exit
	fi

	# Try to get eth0 back by toggling the GPIO named 'GPIO_USB_HOST_POWER_ON'

	logger "recover_eth0.sh: power-cycling USB-host"
	/usr/sbin/export_gpio 55
	echo 0 > /sys/class/gpio/pioB23/value
	usleep 100000
	echo 1 > /sys/class/gpio/pioB23/value
done

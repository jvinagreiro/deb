#!/bin/sh

. /lib/ebee_funcs


# Renames an interface. First argument is the source, second the
# destination. If a third, non-empty argument is pased no error
# messages are emitted.

rename_if()
{
	if ip link set $1 name $2 2>/dev/null
	then
		logger "renamed $1 to $2"
	elif [ -n "$3" ]                      # only if there's no third argument
	then
		logger "failed to rename $1 to $2"
	fi
}


bridge_up()
{
	# We got to rename the interfaces created by the cdc_ether_sh script
	# to musb0 and musb1 before adding them to the (to be created) bridge
	# and bringing them up, both with IP address 0.0.0.0.
	# Unfortunately, we can't be sure about the names of these interfaces
	# as at any moment another usb interface for the connection to the
	# master may appear, mixing up the numbering in unpredictable ways.
	# The only safe way out is first to try to rename all usb[0-2] inter-
	# faces to tmp[0-2] and then rename them a second time (from a name-
	# space where no new interfaces will pop up suddenly) to their final
	# names, using their MAC addresses to select what name to assign. The
	# interface with the MAC address starting with "02:eb:ee:" must be
	# renamed to musb0, the one with "22:eb:ee:" to musb1 and, finally
	# "32:eb:ee:" to usb2. Note: an already active connection to the
	# master (which then is already usb2) can't be renamed, but that's
	# not a problem.

	for iface in $(ls -d /sys/class/net/usb[0-2] 2>/dev/null)
	do
		n=$(basename $iface)
        rename_if $n tmp${n#usb} quiet
	done

	for iface in $(ls -d /sys/class/net/tmp[0-2] 2>/dev/null)
	do
		if grep -q '^02:eb:ee:' "$iface/address" 2>/dev/null
		then
			rename_if $(basename $iface) musb0
		elif grep -q '^22:eb:ee:' "$iface/address" 2>/dev/null
		then
			rename_if $(basename $iface) musb1
		elif grep -q '^32:eb:ee:' "$iface/address" 2>/dev/null
		then
			rename_if $(basename $iface) usb2
		else                                         # anything else unknown
			rename_if $(basename $iface) usb1
		fi
	done

    # Create the bridge with name usb0 - again we have to guard against the
	# sudden appearance of a usb0 interface for the connection to the master.
	# That's why there's the loop around this: the USB connection to the
	# master could come up in between  the test for the existence of usb0
	# and the  creation of the bridge, which then will fail.

	cnt=0
	while [ $cnt -lt 2 ]
	do
		if [ -e /sys/class/net/usb0 ]
		then
			if grep -q '^32:eb:ee:' /sys/class/net/usb0/address 2>/dev/null
			then
				rename_if usb0 usb2
			else
				rename_if usb0 usb1
			fi
		fi

		if brctl addbr usb0 2>/dev/null
		then
			logger "added bridge usb0"
			break
		fi
		cnt=$((cnt+1))
	done

	if [ $cnt -ge 2 ]
	then
		logger "failed to create bridge usb0"
	fi

	# Add both musb0 and musb1 to the bridge and activate them

    brctl addif usb0 musb0
    brctl addif usb0 musb1

	ifconfig musb0 0.0.0.0
	ifconfig musb1 0.0.0.0
}


bridge_down()
{
    # Tear down the bridge as well as the interfaces it was controlling,
    # then rename them back to their original names

    ifconfig musb0 down
    ifconfig musb1 down
    ifconfig usb0 down

    brctl delif usb0 musb1
    brctl delif usb0 musb0
    brctl delbr usb0

	rename_if musb1 usb1
	rename_if musb0 usb0
}


case $@ in
    up)
        bridge_up
        ;;
    down)
        bridge_down
        ;;
    restart)
        "$0" down
        "$0" up
        ;;
    *)
        echo "usage: bridge.sh up|down|restart"
        exit 1
        ;;esac

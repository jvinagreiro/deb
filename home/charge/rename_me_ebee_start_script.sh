#!/bin/sh

MIN_DELAY=60
KEEP_RUNNING=1

# log on console and systemlog
function_log()
{
	echo "ebee_start_script: $1"
	logger -t ebee_start_script "$1"
}


# Convert old persistency files for master/slave mode

function_fix_master_slave()
{
	# If we already have a MasterSlaveMode_ms persistency file no conversion
	# is needed anymore.

	if [ -e /home/charge/persistency/MasterSlaveMode_ms ]
	then
		return
	fi

	# Otherwise do the conversion and remove the old files

	if grep -q '^On' /home/charge/persistency/MasterMode_ms 2>/dev/null
	then
		echo "Master" > /home/charge/persistency/MasterSlaveMode_ms
	elif grep -q '^On' /home/charge/persistency/SlaveMode_ms 2>/dev/null
	then
		echo "Slave" > /home/charge/persistency/MasterSlaveMode_ms
	fi

	rm /home/charge/persistency/MasterMode_ms 2>/dev/null
	rm /home/charge/persistency/MasterMode_ms_default 2>/dev/null
	rm /home/charge/persistency/SlaveMode_ms 2>/dev/null
	rm /home/charge/persistency/SlaveMode_ms_default 2>/dev/null
}


function_fix_master_slave
dmesg > /home/charge/lastbootlog.log
/home/charge/master_slave.sh

# leave ipd empty if tcpdump is not required
#ipd=10.1.0.2 #this is the backend host name or ip
if [ -n "${ipd}" ]; then
	name=/home/charge/tcpdump_${ipd}
	if [[ -e ${name}.cap ]] ; then
		i=0
		while [[ -e ${name}-${i}.cap ]] ; do
			let i++
		done
		name=${name}-${i}
	fi
	tcpdump -n host ${ipd} -i any -w ${name}.cap &
fi

while [ $KEEP_RUNNING -eq 1 ]; do
	function_log "Running ebee cp application"
	rm -f stop_ebee
	T_START=$(awk -F. '{print $1}' /proc/uptime)
	./ebee_cp_plus_application_stripped 2>/dev/null
    ret_val=$?
	function_log "Ebee application return value: $ret_val"
	KEEP_RUNNING=0
	RUNTIME=$(($(awk -F. '{print $1}' /proc/uptime)-${T_START}))
	if [ $ret_val -eq 42 ]; then
		function_log "Ebee application has asked for system reboot"
		echo -n V > /dev/watchdog
	fi
	if [ -e stop_ebee ]; then
		function_log "Administrator wants to exit Ebee without reboot"
	elif [ $ret_val -eq 43 ]; then
		function_log "Ebee application has asked for application reboot without system reboot"
		KEEP_RUNNING=1
	elif [ $ret_val -eq 50 ]; then
		function_log "Ebee application ended to start board test"
		KEEP_RUNNING=2
	fi
	sync
	function_log "End of loop"
done

function_log "Out of loop"

if [ $KEEP_RUNNING -eq 0 ]; then
	#prevent continuous reboot
	function_log "Ebee application running for $RUNTIME seconds"

	if [ -e stop_ebee ]; then
		if [ $ret_val -eq 43 ]; then
			function_log "Ebee application wants to restart itself but admin asked for stop"
		else 
			function_log "Ebee application wants to reboot the system but admin asked for stop"
		fi
	else
		if [ ${RUNTIME} -lt ${MIN_DELAY} ]; then
			DELAY=$((${MIN_DELAY}-${RUNTIME}))
			function_log "Delay reboot by $DELAY seconds. (To prevent continuous reboot you could create stop_ebee)"
			sleep $DELAY
			function_log "Delay done."
		else
			function_log "Skip delay, application runtime > $MIN_DELAY seconds"
		fi

		function_log "Reboot requested by application - rebooting system"
		# prevent reboot hang...
		sync; sync; sync
		echo > /dev/watchdog
		# ...and reboot
		reboot
	fi
elif [ $KEEP_RUNNING -eq 2 ] && [ $ret_val -eq 50 ]; then
	function_log "Starting board test"
    /root/board_test 2>/dev/null
fi

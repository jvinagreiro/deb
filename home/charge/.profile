export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Set a prompt that reflects if this is a master, slave or single
# setup. For master put a '1-' in front, for slave a '-2'. In
# all cases show the user name and the current working directory
# (with the HOME_DIR part appearing as a '~').

if [ "$PS1" ]
then
	if grep -q '^Master$' /home/charge/persistency/MasterSlaveMode_ms 2>/dev/null
	then
		export PS1='M-\u@\w$ '
	elif grep -q '^Slave$' /home/charge/persistency/MasterSlaveMode_ms 2>/dev/null
	then
		export PS1='S-\u@\w$ '
	else
		export PS1='\u@\w$ '
	fi
fi

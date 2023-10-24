#!/bin/sh

rip='((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}'
rdm='([a-z][a-z0-9-]*\.)+[a-z0-9][a-z0-9-]+$'
run='^[a-z0-9_-]+'

if echo $1 | grep -Eiq "$run\@($rdm|$rip)"
then
	logger Ebee custom script invoked with parameter $1
	ssh $1 -R 1111:localhost:22 -y -N -f -i /home/charge/.ssh/id_rsa & 
	logger Ebee custom script invocation completed
else
	logger Ebee custom script not invoked: Argument does not match user@domain 
fi

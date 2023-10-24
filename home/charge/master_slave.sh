#!/bin/sh

if [ ! -e /home/charge/persistency/MasterSlaveMode_ms ]
then
	return
fi

if grep -q '^Off$' /home/charge/persistency/MasterSlaveMode_ms 2>/dev/null
then
	return
fi


#### common section ####

logger "Starting general OCPP Master/Slave port forwarding"

# HTTP server of master can be reached via port 81, that of slave via port 82

socat -ly tcp4-listen:81,fork,reuseaddr tcp4-connect:192.168.125.124:80 &
socat -ly tcp4-listen:82,fork,reuseaddr tcp4-connect:192.168.125.125:80 &

# SSH server of master can be reached via port 23, that of slave via port 24

socat -ly tcp4-listen:23,fork,reuseaddr tcp4-connect:192.168.125.124:22 &
socat -ly tcp4-listen:24,fork,reuseaddr tcp4-connect:192.168.125.125:22 &

# Firmware upload and log download from master via port 9021, from slave via
# poer 9022

socat -ly tcp4-listen:8021,fork,reuseaddr tcp4-connect:192.168.125.124:8020 &
socat -ly tcp4-listen:8022,fork,reuseaddr tcp4-connect:192.168.125.125:8020 &

#### OCPP slave section section ####

#if grep -q '^Slave$' /home/charge/persistency/MasterSlaveMode_ms 2>/dev/null
#then
#
#fi


#### OCPP master section section #

if grep -q '^Master$' /home/charge/persistency/MasterSlaveMode_ms 2>/dev/null
then
	logger "Starting port forwarding for Modbus TCP Slave"
  modbus_base_port=502 # set the default
  if [ -e /home/charge/persistency/TCPPortNumber_modbus_slave ]; then
      modbus_base_port=$(head -n 1 /home/charge/persistency/TCPPortNumber_modbus_slave)
  fi;
  socat -ly tcp4-listen:$((modbus_base_port+1)),fork,reuseaddr tcp4-connect:192.168.125.125:$modbus_base_port &
    
  logger "Starting port forwarding for ASKI over OCPP-S"
  socat -ly tcp4-listen:13001,fork,reuseaddr tcp4-connect:192.168.125.125:13000 &    
fi

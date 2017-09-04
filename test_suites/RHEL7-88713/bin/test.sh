#!/bin/bash

# Description:
# Trigger iperf3 for network performance test.
# $1: role; "client" or "server"
# $2: the ip address of mated system

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

# parameters
if [ "$1" != "client" ] && [ "$1" != "server" ]; then
	echo "\$1, represents the role, should be \"client\" or \"server\"."
	exit 1
else
	label="$1"
fi

if [ -z "$2" ]; then
	echo "\$2, specify the ip address, must be provisioned."
	exit 1
else
	ip="$2"
fi

# set the log name
inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/network_performance_${inst_type}_${label}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform test

function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

run_cmd 'setup_iperf3.sh'

echo -e "\n\nTest Results:\n===============\n" >> $logfile

#run_cmd 'sudo ifconfig eth0 mtu 9000'	# adjust MTU

# basic information
run_cmd 'ip addr'
run_cmd 'ethtool -i eth0'

# driver
driver=$(ethtool -i eth0 | grep "^driver:" | awk '{print $2}')
echo -e "\nThe dirver of \"eth0\" is \"$driver\".\n" >> $logfile
run_cmd "modinfo $driver"

# features
run_cmd 'ethtool -k eth0'

# connectivity
run_cmd "ping -c 8 $ip"
run_cmd "tracepath $ip"

# statistics
run_cmd 'ethtool -S eth0'

# performance test
if [ "$label" = "server" ]; then
	# start server
	
	echo -e "\nStart server:\n--------------------" >> $logfile
	iperf_server.sh $logfile 32

	# exit without teardown
	exit 0
else
	# iperf test on client

	# Usage: iperf_client.sh <logfile> <driver> <process> <ip> <protocol> <buffer> <pclient> <time>
	iperf_client.sh $logfile $driver 8 $ip tcp 128k 32 60

	# check the statistics again
	run_cmd 'ethtool -S eth0'
fi

# teardown
teardown.sh

exit 0


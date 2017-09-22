#!/bin/bash

# Description:
# Trigger iperf3 for network performance test.
# $1: role; "client" or "server"
# $2: the ipv4 address of mated system
# $3: the ipv6 address of mated system (optional)

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

# parameters
if [ "$1" != "client" ] && [ "$1" != "server" ]; then
	echo "\$1, represents the role, should be \"client\" or \"server\"."
	exit 1
fi

if [ -z "$2" ]; then
	echo "\$2, specify the ip address, must be provisioned."
	exit 1
fi

label="$1"
ip="$2"
ipv6="$3"

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

echo -e "\nSetup iperf3...\n" >> $logfile
setup_iperf3.sh 2>> $logfile

if [ "$(os_type.sh)" = "redhat" ]; then
	echo -e "\nEnable IPv6 on RHEL system...\n" >> $logfile
	enable_ipv6_on_rhel.sh &>> $logfile
fi

echo -e "\n\nTest Results:\n===============\n" >> $logfile

#run_cmd 'sudo ifconfig eth0 mtu 9000'	# adjust MTU

# basic information
run_cmd 'ifconfig'
run_cmd 'ip addr'
run_cmd 'ethtool -i eth0'

# driver
driver=$(ethtool -i eth0 | grep "^driver:" | awk '{print $2}')
echo -e "\nThe dirver of \"eth0\" is \"$driver\".\n" >> $logfile
run_cmd "modinfo $driver"
run_cmd "dmesg|grep -w $driver"	# Added for ena dmesg

# features
run_cmd 'ethtool -k eth0'

# connectivity
run_cmd "ping -c 8 $ip"
run_cmd "tracepath $ip"

# connectivity - ipv6
if [ ! -z "$ipv6" ]; then
	run_cmd "ping6 -c 8 ${ipv6}"
	run_cmd "tracepath6 ${ipv6}"
fi

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

	if [ ! -z "$ipv6" ]; then
		iperf_client.sh $logfile $driver 8 ${ipv6} tcp 128k 32 60
	fi

	# check the statistics again
	run_cmd 'ethtool -S eth0'
fi

# teardown
teardown.sh

exit 0


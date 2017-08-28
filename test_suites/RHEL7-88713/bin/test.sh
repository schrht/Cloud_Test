#!/bin/bash

# Description:
# Trigger iperf3 for network performance test.
# $1: "" for server
#     "server's ip" for client

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

if [ "$1" = "" ]; then
	label="server"
else
	label="client"
fi
inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
logfile=~/workspace/log/network_performance_${inst_type}_${label}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

run_cmd 'setup_iperf3.sh'

echo -e "\n\nTest Results:\n===============\n" >> $logfile

#run_cmd 'sudo ifconfig eth0 mtu 9000'	# adjust MTU

run_cmd 'ip addr'

run_cmd 'modinfo ena'
run_cmd 'ethtool -i eth0'
run_cmd 'ethtool -k eth0'

if [ "$1" = "" ]; then
	# server side
	run_cmd 'sudo iperf3 -s -D'	# server started as demon
	exit 0
else
	# client side ("$1" is server's ip)
	#iperf_client.sh $logfile $1 '128k' '1'
	#iperf_client.sh $logfile $1 '128k' '64'
	#iperf_client.sh $logfile $1 '1m' '1'
	#iperf_client.sh $logfile $1 '1m' '64'

	run_cmd "tracepath $1"
	run_cmd "ping -c 10 $1"
	run_cmd 'ethtool -S eth0'
	iperf_client.sh $logfile $1 '128k' '32'
	run_cmd 'ethtool -S eth0'
fi

# teardown
teardown.sh

exit 0


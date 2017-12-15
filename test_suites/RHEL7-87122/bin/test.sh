#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/result_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

run_cmd "sudo yum install -y pciutils"
run_cmd "sudo yum install -y nvme-cli"

run_cmd 'lspci | grep Non-Volatile'
run_cmd 'lsmod | grep nvme'

run_cmd 'sudo nvme list'

devlist=$(sudo nvme list | grep dev | cut -d " " -f 1)
for dev in $devlist; do
	run_cmd "sudo nvme read --data=/dev/null --data-size=10000 --latency $dev"
	run_cmd "sudo nvme write --data=/dev/zero --data-size=10000 --latency $dev"
done

# teardown
teardown.sh

exit 0


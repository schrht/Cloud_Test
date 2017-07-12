#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

label=$1  # label: create, reboot1, reboot2...
inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
logfile=~/workspace/log/boot_time_${inst_type}_${label}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

echo -e "\n\nTest Results:\n===============\n" >> $logfile

run_cmd 'sudo systemd-analyze time'
run_cmd 'sudo systemd-analyze blame'
run_cmd 'sudo systemd-analyze critical-chain'
run_cmd 'sudo systemd-analyze dot'

# teardown
teardown.sh

exit 0


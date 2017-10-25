#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/result_2_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

cd ~/workspace/
echo "Part (2/2) start..." >> $logfile

## testing
echo "** Added intel_idle.max_cstate=1 option to set C1 as the deepest C-state for idle cores. **" >> $logfile

run_cmd 'cat /proc/cmdline'
run_cmd 'sudo turbostat stress -c 2 -t 10'

## disable Turbo Boost
echo "** Disable Turbo Boost. **" >> $logfile

run_cmd 'sudo sh -c "echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo"'
run_cmd 'sudo turbostat stress -c 2 -t 10'

## finish
echo "Part (2/2) finished..." >> $logfile

# teardown
teardown.sh

exit 0


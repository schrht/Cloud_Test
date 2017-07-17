#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
logfile=~/workspace/log/resource_validation_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

echo -e "\n\nTest Results:\n===============\n" >> $logfile

run_cmd 'lscpu'
run_cmd 'free -k'

run_cmd 'cat /proc/cpuinfo'
run_cmd 'cat /proc/meminfo'

CPU=$(grep "^CPU(s):" $logfile | awk '{print $2}')
MEM=$(grep "^MemTotal:" $logfile | awk '{print $2}')

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $logfile
printf "** %-12s %-5s %-12s\n" VMSize "CPU#" "MemSize(kB)" >> $logfile
printf "** %-12s %-5s %-12s\n" $inst_type $CPU $MEM >> $logfile

# teardown
teardown.sh

exit 0


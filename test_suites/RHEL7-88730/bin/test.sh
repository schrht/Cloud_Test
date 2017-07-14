#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
logfile=~/workspace/log/storage_performance_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

echo -e "\n\nTest Results:\n===============\n" >> $logfile

run_cmd 'setup_fio.sh'

run_cmd 'lsblk -d'
run_cmd 'lsblk -t'

## fio.sh $log $disktype $rw $bs $iodepth
run_cmd 'fio.sh $logfile GP2 read 4k 1'
run_cmd 'fio.sh $logfile GP2 write 4k 1'


# teardown
teardown.sh

exit 0


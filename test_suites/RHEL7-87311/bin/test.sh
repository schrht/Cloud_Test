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

cmd='sudo grep "^" /sys/block/*/queue/discard_max_bytes'

echo "$ $cmd" >> $logfile
eval $cmd >> $logfile 2>&1

# teardown
teardown.sh

exit 0


#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
logfile=~/workspace/log/iperf3_client_${inst_type}_${time_stamp}.log

setup_iperf3.sh

# configure system
sudo ifconfig eth0 mtu 9000

# run test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

echo "sudo iperf3 -c $1 -t 20 -i 1" >> $logfile
eval "sudo iperf3 -c $1 -t 20 -i 1" >> $logfile 2>&1

exit 0


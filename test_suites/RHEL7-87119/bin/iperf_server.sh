#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/iperf3_server_${inst_type}_${time_stamp}.log

setup_iperf3.sh

# configure system
sudo ifconfig eth0 mtu 9000

# run test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

echo "sudo iperf3 -s -D &" >> $logfile
sudo iperf3 -s -D &

exit 0


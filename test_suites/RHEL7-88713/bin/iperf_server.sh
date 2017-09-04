#!/bin/bash

# Description: Start iperf3 server
# $1: log file
# $2: process number

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# check input
if [ "$2" -ge "1" ] && [ "$2" -le "32" ]; then
	process_number=$2
else
	echo "invalid input for process number, \"$2\" should between \"1\" and \"32\", use \"32\" instead." >> $tlog
	process_number="32"
fi

# log file
tlog=$(mktemp)
logfile=$1

# stop previous server
#sudo kill $(pidof iperf3) 

# start server
for pn in $(seq $process_number); do
	echo "Start iperf3 server, listen on port $((10080+$pn));" >> $tlog
	iperf3 -s -p $((10080+$pn)) -D &>> $tlog
done

# Save log
cat $tlog >> $logfile && rm $tlog

exit 0

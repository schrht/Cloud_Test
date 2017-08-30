#!/bin/bash

# Description:
# $1: logfile
# $2: driver
# $3: iperf - Server's IP
# $4: iperf - protocol (tcp, udp)
# $5: iperf - buffer length (1m, 128k, ...)
# $6: iperf - parallel client (1, 2, 4, 8, ...)
# $7: iperf - time in second

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

vmsize=$(ec2-metadata -t | awk '{print $2}')
iface=eth0
driver=$2
server_ip=$3
protocol=$4
len=$5
pc=$6
time=$7

tlog=$(mktemp)
logfile=$1

# Set Command
cmd="sudo /usr/bin/iperf3 -c $server_ip -l $len -P $pc -t $time -f m"

# Run test
echo -e "\nTest Run: \n----------\n" >> $tlog
echo -e "\n$ $cmd" >> $tlog
eval $cmd >> $tlog 2>&1

# Get the BW
BWtx=`grep "sender" $tlog | tail -1 | cut -d] -f2 | awk '{print $5}'`
BWrx=`grep "receiver" $tlog | tail -1 | cut -d] -f2 | awk '{print $5}'`

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $tlog
printf "** %-12s %-10s %-8s %-8s %-6s %-7s %-10s %-10s\n" VMSize Interface Driver Protocol Buffer PClient "BWtx(Mb/s)" "BWrx(Mb/s)" >> $tlog
printf "** %-12s %-10s %-8s %-8s %-6s %-7s %-10s %-10s\n" $vmsize $iface $driver $protocol $len $pc $BWtx $BWrx >> $tlog

# Save log
cat $tlog >> $logfile && rm $tlog

exit 0


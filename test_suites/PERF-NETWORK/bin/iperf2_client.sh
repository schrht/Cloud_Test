#!/bin/bash

# Description:
# $1: logfile
# $2: driver
# $3: process number
# $4: iperf - Server's IP
# $5: iperf - protocol (tcp, udp)
# $6: iperf - buffer length (1m, 128k, ...)
# $7: iperf - parallel client (1, 2, 4, 8, ...)
# $8: iperf - time in second

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# check inputs
vmsize=$(ec2-metadata -t | awk '{print $2}')
iface=eth0
driver=$2
pnum=$3
ipaddr=$4
tprot=$5
len=$6
pc=$7
time=$8

if [ "$tprot" != "tcp" ] && [ "$tprot" != "udp" ]; then
	echo -e "\n$0: Invalid input: \$tprot must be \"tcp\" or \"udp\".\n" >> $1
	exit 1
fi

if [[ "$ipaddr" =~ ":" ]]; then
	nprot="ipv6"
else
	nprot="ipv4"
fi

protocol="$nprot:$tprot"

# log file
tlog=$(mktemp)
logfile=$1

# start test
echo -e "\n\nIPERF2 TEST BLOCK" >> $tlog
echo -e "Multiple Tasks START: $(date)" >> $tlog

# currently support pnum=1
pnum=1

# Set Command
if [ $nprot = "ipv4" ]; then
	cmd="sudo iperf -c $ipaddr -p 20080 -l $len -P $pc -t $time -f m"
else
	cmd="sudo iperf -c $ipaddr -p 30080 -l $len -P $pc -t $time -f m -V"
fi

# Run test
echo -e "\n$ $cmd" >> $tlog
eval $cmd &>> $tlog

echo -e "Multiple Tasks FINISH: $(date)" >> $tlog

# Get the BW

# Example:
# [SUM]   0.00-60.00  sec  3.63 GBytes   520 Mbits/sec  24943             sender
# [SUM]   0.00-60.00  sec  67.2 GBytes  9615 Mbits/sec  32387             sender
# [SUM]   0.00-60.00  sec  6.72 GBytes   962 Mbits/sec  40239             sender
# [SUM]   0.00-60.00  sec  8.43 GBytes  1207 Mbits/sec  16725             sender

BWtx=$(grep "SUM" $tlog | awk '{print $6}')
BWrx="{iperf2}"

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $tlog
printf "** %-14s %-10s %-8s %-8s %-7s %-7s %-6s %-10s %-10s\n" VMSize Interface Driver Protocol Process PClient Buffer "BWtx(Mb/s)" "BWrx(Mb/s)" >> $tlog
printf "** %-14s %-10s %-8s %-8s %-7s %-7s %-6s %-10s %-10s\n" $vmsize $iface $driver $protocol $pnum $pc $len $BWtx $BWrx >> $tlog

# Save to log file
cat $tlog >> $logfile && rm $tlog

exit 0


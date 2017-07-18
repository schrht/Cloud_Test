#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

label=$1  # label: create, reboot...
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

# Get Performance KPI
grep "Startup finished in" $logfile | grep "(initrd)" >/dev/null 2>&1

if [ "$?" = "0" ]; then
	# Startup finished in 1.890s (kernel) + 950ms (initrd) + 3.456s (userspace) = 6.296s
	kernel=$(grep "Startup finished in" $logfile | head -1 | awk '{print $4}')
	initrd=$(grep "Startup finished in" $logfile | head -1 | awk '{print $7}')
	userspace=$(grep "Startup finished in" $logfile | head -1 | awk '{print $10}')
	total=$(grep "Startup finished in" $logfile | head -1 | awk '{print $13}')
else
	# Startup finished in 3.713s (kernel) + 4.430s (userspace) = 8.144s
	kernel=$(grep "Startup finished in" $logfile | head -1 | awk '{print $4}')
	initrd="-"
	userspace=$(grep "Startup finished in" $logfile | head -1 | awk '{print $7}')
	total=$(grep "Startup finished in" $logfile | head -1 | awk '{print $10}')
fi

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $logfile
printf "** %-12s %-10s %-10s %-10s %-10s %-10s\n" VMSize Method Kernel Initrd Userspace Total >> $logfile
printf "** %-12s %-10s %-10s %-10s %-10s %-10s\n" ${inst_type} ${label} $kernel $initrd $userspace $total >> $logfile

# teardown
teardown.sh

exit 0


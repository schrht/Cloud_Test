#!/bin/bash

# History:
# v1.0.0  2017-08-07  charles.shih  Init version
# v2.0.0  2018-09-25  charles.shih  Convert time to seconds

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
#setup.sh

label=$1  # label: create, reboot...
inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
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

# Waiting for Bootup finished
while [[ "$(sudo systemd-analyze time 2>&1)" =~ "Bootup is not yet finished" ]]; do
	echo "[$(date)] Bootup is not yet finished." >> $logfile
	sleep 2s
done

run_cmd 'rpm -qa | grep kexec'
run_cmd 'rpm -qa | grep cloud-init'
run_cmd 'rpm -qa | grep rh-amazon-rhui-client'

run_cmd 'sudo systemd-analyze time'
run_cmd 'sudo systemd-analyze blame'
run_cmd 'sudo systemd-analyze critical-chain'
run_cmd 'sudo systemd-analyze dot'

# Get Performance KPI
line=$(grep "Startup finished in" $logfile | head -1 | sed 's/min /min/g')

if [[ "$line" =~ "(initrd)" ]]; then
	# TARGET: "Startup finished in 1.890s (kernel) + 950ms (initrd) + 3.456s (userspace) = 6.296s"
	# TARGET: "Startup finished in 2.333s (kernel) + 3.913s (initrd) + 1min18.659s (userspace) = 1min24.905s"
	kernel=$(echo $line | awk '{print $4}')
	initrd=$(echo $line | awk '{print $7}')
	userspace=$(echo $line | awk '{print $10}')
	total=$(echo $line | awk '{print $13}')
else
	# TARGET: "Startup finished in 3.713s (kernel) + 4.430s (userspace) = 8.144s"
	kernel=$(echo $line | awk '{print $4}')
	initrd="-"
	userspace=$(echo $line | awk '{print $7}')
	total=$(echo $line | awk '{print $10}')
fi

# Convert time to seconds
function convert2sec() {
	# $@ : the STRING in time format
	#      1min54s
	#      1min245ms
	# Description:
	#      It takes a time STRING, convert and echo as a value in seconds

        [[ "$@" != [0-9]* ]] && echo "$@" && return

	remaining="$@"

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w min
	if [ $? = 0 ]; then
		mstr=${remaining%%min*}
		remaining=${remaining#*min}
	fi

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w s
	if [ $? = 0 ]; then
		sstr=${remaining%%s*}
		remaining=${remaining#*s}
	fi

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w ms
	if [ $? = 0 ]; then
		msstr=${remaining%%ms*}
	fi

	echo ${mstr:=0} ${sstr:=0} ${msstr:=0} | awk '{print $1*60+$2+$3/1000}'
}

kernel=$(convert2sec kernel)
initrd=$(convert2sec initrd)
userspace=$(convert2sec userspace)
total=$(convert2sec total)

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $logfile
printf "** %-12s %-10s %-10s %-10s %-11s %-11s\n" VMSize Method Kernel Initrd Userspace Total >> $logfile
printf "** %-12s %-10s %-10s %-10s %-11s %-11s\n" ${inst_type} ${label} $kernel $initrd $userspace $total >> $logfile

# teardown
#teardown.sh

exit 0

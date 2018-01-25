#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
#setup.sh

label=$1  # label: create, reboot...
inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/resource_validation_${inst_type}_${label}_${time_stamp}.log
tmplog=${logfile}.temp

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $tmplog
	eval $1 >> $tmplog 2>&1
}

echo -e "\n\nTest Results:\n===============\n" >> $tmplog

run_cmd 'lscpu'
run_cmd 'free -k'

run_cmd 'cat /proc/cpuinfo'
run_cmd 'cat /proc/meminfo'

CPU=$(grep "^CPU(s):" $tmplog | awk '{print $2}')
MEM=$(grep "^MemTotal:" $tmplog | awk '{print $2}')

# nproc should equal to CPU number
if [ "$(nproc)" != "$CPU" ]; then
	echo "* WARNING: nproc is mismatched with CPU number!!! ($(nproc) != $CPU)" >> $tmplog
else
	echo "* PASSED: nproc is matched with CPU number. ($(nproc) = $CPU)" >> $tmplog
fi

# Check CPU flags
if [ "$(sed -n 's/^flags.*://p' $tmplog | sort -u | wc -l)" != "1" ]; then
	# CPU flags mismatched
	echo "* ERROR: Processes kept mismatched CPU flags." >> $tmplog
else
	# Get CPU flags, remove blanks from head/tail, get 1-7 chars of MD5 (for further comparison)
	FLAGS=$(sed -n 's/^flags.*://p' $tmplog | sort -u | xargs echo | md5sum | cut -c 1-7)
fi

# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $tmplog
printf "** %-12s %-5s %-12s %-12s\n" VMSize "CPU#" "MemSize(KiB)" Flags >> $tmplog
printf "** %-12s %-5s %-12s %-12s\n" $inst_type $CPU $MEM $FLAGS >> $tmplog

# Additional validation
run_cmd 'sudo virt-what'

# Combine log files
cat $tmplog >> $logfile && rm $tmplog


# teardown
#teardown.sh

exit 0


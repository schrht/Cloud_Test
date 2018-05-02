#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_id=$(metadata.sh -i | awk '{print $2}')
inst_type=$(metadata.sh -t | awk '{print $2}')
test_name=resource_validation
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/${inst_id}_${inst_type}_${test_name}_${time_stamp}.log
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

# CPU
run_cmd 'lscpu'
run_cmd 'cat /proc/cpuinfo'

# nproc should equal to CPU number
if [ "$(nproc)" != "$CPU" ]; then
	echo "* WARNING: nproc is mismatched with CPU number!!! ($(nproc) != $CPU)" >> $tmplog
	CPU=$(grep "^CPU(s):" $tmplog | awk '{print $2}'):$(nproc)
else
	echo "* PASSED: nproc is matched with CPU number. ($(nproc) = $CPU)" >> $tmplog
	CPU=$(grep "^CPU(s):" $tmplog | awk '{print $2}')
fi

# Check CPU flags
if [ "$(sed -n 's/^flags.*://p' $tmplog | sort -u | wc -l)" != "1" ]; then
	# CPU flags mismatched
	echo "* ERROR: Processes kept mismatched CPU flags." >> $tmplog
	FLAGS="ERROR"
else
	# Get CPU flags, remove blanks from head/tail, get 1-7 chars of MD5 (for further comparison)
	FLAGS=$(sed -n 's/^flags.*://p' $tmplog | sort -u | xargs echo | md5sum | cut -c 1-7)
fi

# Memory
run_cmd 'free -k'
run_cmd 'cat /proc/meminfo'
MEM=$(grep "^MemTotal:" $tmplog | awk '{print $2}')


# Write down a summary
echo -e "\nTest Summary: \n----------\n" >> $tmplog
printf "** %-12s %-5s %-12s %-12s\n" VMSize "CPU#" "MemSize(KiB)" Flags >> $tmplog
printf "** %-12s %-5s %-12s %-12s\n" $inst_type $CPU $MEM $FLAGS >> $tmplog

# Additional validation
run_cmd 'sudo virt-what'

# Combine log files
cat $tmplog >> $logfile && rm $tmplog

exit 0


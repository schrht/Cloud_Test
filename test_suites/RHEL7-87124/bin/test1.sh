#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/result_1_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

function run_cmd(){
	# $1: Command

	echo -e "\n$ $1" >> $logfile
	eval $1 >> $logfile 2>&1
}

cd ~/workspace/
echo "Part (1/2) start..." >> $logfile

## setup kernel-tools
rpm -qa | grep kernel-tools >> /dev/null 2>&1
if [ "$?" != "0" ]; then
	sudo yum install -y kernel-tools
fi

run_cmd 'rpm -qa | grep kernel-tools'

## setup stress
rpm -qa | grep stress >> /dev/null 2>&1
if [ "$?" != "0" ]; then
	run_cmd 'sudo yum install -y wget'
	run_cmd 'wget http://rpmfind.net/linux/epel/7/x86_64/Packages/s/stress-1.0.4-16.el7.x86_64.rpm'
	run_cmd 'sudo rpm -ivh stress-*.rpm'
fi

run_cmd 'rpm -qa | grep stress'

## testing
cpu_num=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
run_cmd 'sudo turbostat stress -c 2 -t 10'
run_cmd "sudo turbostat stress -c $cpu_num -t 10"

## modify kernel parameter, add "intel_idle.max_cstate=1"
## (directly edit `/boot/grub2/grub.cfg`, since `sed -i` can't work with s-link)
grubcfg=/boot/grub2/grub.cfg

# for RHEL6
[[ "$(rpm -qa | grep --max-count=1 ^kernel-[0-9])" =~ "el6" ]] && grubcfg=/boot/grub/grub.conf

run_cmd "cat /proc/cmdline"
run_cmd "sudo cp $grubcfg ${grubcfg}.bak"
run_cmd "sudo sed -i 's/intel_idle.max_cstate=[0-9]*//' $grubcfg"
run_cmd "sudo sed -i 's/\(linux16.*\)/\1 intel_idle.max_cstate=1/' $grubcfg"
run_cmd "sudo diff ${grubcfg}.bak $grubcfg"

## reboot
run_cmd 'sleep 5s && sudo reboot&'

echo "Part (1/2) finished..." >> $logfile

exit 0


#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(date +%y%m%d%H%M%S)
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
	sudo yum install -y wget
	run_cmd 'wget ftp://rpmfind.net/linux/epel/7/x86_64/s/stress-1.0.4-16.el7.x86_64.rpm'
	run_cmd 'sudo rpm -ivh stress-1.0.4-16.el7.x86_64.rpm'
fi

run_cmd 'rpm -qa | grep stress'

## testing
cpu_num=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
run_cmd 'sudo turbostat stress -c 2 -t 10'
run_cmd "sudo turbostat stress -c $cpu_num -t 10"

## modify kernel parameter, add "intel_idle.max_cstate=1"
## (directly edit `/boot/grub2/grub.cfg`, since `sed -i` can't work with s-link)
sudo sed -i 's/intel_idle.max_cstate=[0-9]*//' /boot/grub2/grub.cfg
sudo sed -i 's/\(linux16.*\)/\1 intel_idle.max_cstate=1/' /boot/grub2/grub.cfg

## reboot
run_cmd 'sleep 5s && sudo reboot&'

echo "Part (1/2) finished..." >> $logfile

exit 0


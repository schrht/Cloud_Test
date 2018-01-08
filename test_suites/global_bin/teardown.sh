#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# Please note:
# The commands in this script will be executed on every
# instance after test steps. You can use this script to
# do some general clean-up affairs.

# Common clean up


# log dmesg

inst_type=$(metadata.sh -t | awk '{print $2}')
inst_id=$(metadata.sh -i | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/dmesg_${inst_type}_${inst_id}_${time_stamp}.log


if [[ "$(cat /etc/redhat-release)" = "Red Hat Enterprise Linux Server release 6."* ]]; then
	dmesg >> $logfile
else
	function log_dmesg(){
		echo -e "\n$ dmesg $@\n------------------" >> $logfile
		dmesg $@ >> $logfile
	}

	log_dmesg -l emerg
	log_dmesg -l alert
	log_dmesg -l crit
	log_dmesg -l err
	log_dmesg -l warn
	log_dmesg -l notice
	log_dmesg -l info
	log_dmesg -l debug
fi


# code coverage

type lcov &>/dev/null
if [ $? -eq 0 ]; then
	logfile=~/workspace/log/lcov_${inst_type}_${inst_id}_${time_stamp}.info
	sudo lcov -c -b /root/rpmbuild/BUILD/kernel-3.10.0-799.el7/linux-3.10.0-799.el7.x86_64/ -o $logfile
fi

exit 0


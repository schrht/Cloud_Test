#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

function show(){
	# $1: Title;
	# $@: Command;

	if [ "$1" = "" ]; then
		echo -e "\n\$$@"
	else
		echo -e "\n* $1"
	fi
	echo -e "---------------"; shift
	$@ 2>&1
} 

show "Time" date
show "Release" cat /etc/system-release
show "" systemd-analyze
show "" uname -a
show "" lsblk -p
show "" ifconfig -a
show "EC2-Metadata" ec2-metadata

exit 0


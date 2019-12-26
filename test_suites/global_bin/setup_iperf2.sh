#!/bin/bash

# Description:
# This script is used to ensure iperf2 is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace/bin

type iperf >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then

	if [ ! -e ./iperf-2.0.13-1.el7.x86_64.rpm ]; then
		# download rpm and install
		curl -O http://www.rpmfind.net/linux/epel/7/x86_64/Packages/i/iperf-2.0.13-1.el7.x86_64.rpm
	fi

	sudo rpm -ivh ./iperf-2.0.13-1.el7.x86_64.rpm
	rpm -qa | grep iperf
fi

exit 0


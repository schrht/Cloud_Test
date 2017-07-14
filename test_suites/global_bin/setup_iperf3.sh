#!/bin/bash

# Description:
# This script is used to ensure iperf3 is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace

type iperf3 >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then
	# setup epel repos
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
	sudo rpm -ivh epel-release-7-10.noarch.rpm

	# setup iperf3
	sudo yum install -y iperf3
	rpm -qa | grep iperf3
else
	sudo apt install -y iperf3
	dpkg -s iperf3
fi

exit 0


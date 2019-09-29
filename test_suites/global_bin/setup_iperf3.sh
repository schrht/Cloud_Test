#!/bin/bash

# Description:
# This script is used to ensure iperf3 is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace/bin

type iperf3 >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then

	if [ ! -e ./iperf3-3.1.3-1.fc24.x86_64.rpm ]; then
		# download rpm and install
		curl -O https://iperf.fr/download/fedora/iperf3-3.1.3-1.fc24.x86_64.rpm
	fi

	sudo rpm -ivh iperf3-3.1.3-1.fc24.x86_64.rpm
	rpm -qa | grep iperf3
else
	sudo apt install -y iperf3
	dpkg -s iperf3
fi

exit 0


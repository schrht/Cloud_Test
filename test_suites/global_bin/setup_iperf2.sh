#!/bin/bash

# Description:
# This script is used to ensure iperf2 is available.
#
# https://iperf.fr/iperf-download.php#fedora
#

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace/bin

type iperf >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then

	if [ ! -e ./iperf-2.0.8-2.fc23.x86_64.rpm ]; then
		# download rpm and install
		curl -O https://iperf.fr/download/fedora/iperf-2.0.8-2.fc23.x86_64.rpm
	fi

	sudo rpm -ivh ./iperf-2.0.8-2.fc23.x86_64.rpm
	rpm -qa | grep iperf
fi

exit 0


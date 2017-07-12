#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

type iperf3 >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then
	sudo yum install -y iperf3
	rpm -qa | grep iperf3
else
	sudo apt install -y iperf3
	dpkg -s iperf3
exit 0


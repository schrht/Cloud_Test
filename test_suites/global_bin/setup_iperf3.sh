#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

type iperf3 >/dev/null 2>&1 && echo "Already Installed." && exit 0

sudo yum-config-manager --disable rhel7u4-debug >/dev/null 2>&1
sudo yum install -y iperf3
rpm -qa | grep iperf3

exit 0


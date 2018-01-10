#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# Please note:
# The commands in this script will be executed on every
# instance before test steps. You can use this script to
# do some general configuration, such as configure the
# yum repos or deal with something based on the image.

# Common Configuration & Setup
if [ "$(os_type.sh)" = "redhat" ]; then

	# disable unavailable repo
#	echo "disable unavailable repo rhel7u5-debug"
#	sudo yum-config-manager --disable rhel7u5-debug

#	cd ~/workspace/bin

	# downgrade rdma-core from 13-7 to 13-5
#	rpm -q rdma-core | grep rdma-core-13-7 >/dev/null 2>&1
#	if [ "$?" = "0" ]; then
#		echo "downgrade rdma-core from 13-7 to 13-5"
#		sudo yum downgrade -y rdma-core-13-5.el7.x86_64
#	fi

	echo
fi

exit 0


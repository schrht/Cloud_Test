#!/bin/bash

# Description:
# This script is used to ensure fio is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace
EPEL7_ADDRESS="http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm"

type fio >/dev/null 2>&1 && echo "Already Installed." && exit 0
result=`bash os_type.sh`
if [ "${result}" = "redhat" ]; then

	# install for redhat
	sudo yum install -y wget libaio-devel

	# setup epel repos
	#wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
        wget ${EPEL7_ADDRESS} 1> /dev/null 2> /dev/null
	sudo rpm -ivh ${EPEL7} 1> /dev/null 2> /dev/null
	sudo yum install -y fio --enablerepo=epel
else
	sudo apt install -y git gcc libaio-devel

	git clone https://github.com/axboe/fio/

	cd fio
	./configure && make && sudo make install || exit 1
fi

exit 0


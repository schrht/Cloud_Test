#!/bin/bash

# Description:
# This script is used to ensure fio is available.

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

cd ~/workspace

type fio &>/dev/null && echo "Already Installed." && exit 0

result=`bash os_type.sh`
if [ "${result}" = "redhat" ]; then
	# install for redhat
	sudo yum install -y libaio-devel

	wget https://github.com/axboe/fio/archive/fio-3.3.tar.gz &>/dev/null
	tar -xvf ./fio*.tar.gz
	cd ./fio-fio* && ./configure && make && sudo make install || exit 1

	# create link for sudo command to run fio
	[ ! -f /usr/bin/fio ] && sudo ln -s /usr/local/bin/fio /usr/bin/
else
	sudo apt install -y git gcc libaio-devel

	git clone https://github.com/axboe/fio/

	cd fio
	./configure && make && sudo make install || exit 1
fi

exit 0


#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

type fio >/dev/null 2>&1 && echo "Already Installed." && exit 0

if [ "$(os_type.sh)" = "redhat" ]; then
	sudo yum install -y git gcc libaio-devel
else
	sudo apt install -y git gcc libaio-devel
fi

cd ~/workspace
git clone https://github.com/axboe/fio/

cd fio
./configure && make && sudo make install || exit 1

exit 0


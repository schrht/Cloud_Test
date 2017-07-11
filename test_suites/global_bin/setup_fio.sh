#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

type fio >/dev/null 2>&1 && echo "Already Installed." && exit 0

sudo yum-config-manager --disable rhel7u4-debug >/dev/null 2>&1
sudo yum install -y git gcc libaio-devel
cd ~/workspace
git clone https://github.com/axboe/fio/
cd fio
./configure && make && sudo make install || exit 1

exit 0


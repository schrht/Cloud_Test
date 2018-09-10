#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
base=$HOME/workspace/log/full_metadata_${inst_type}_${time_stamp}
mkdir -p $base
testlog=$base/full_metadata.log

# perform this test
full_metadata.sh > $testlog

exit 0


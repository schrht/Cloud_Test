#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
testlog=$HOME/workspace/log/sos_report_${inst_type}_${time_stamp}.log

# perform this test
function run_cmd(){
	# $1: Command to be executed

	echo -e "\ncmd> $1\n" >> $testlog
	eval $1 >> $testlog 2>&1

	return $?
}

# Waiting for Bootup finished
while [[ "$(sudo systemd-analyze time 2>&1)" =~ "Bootup is not yet finished" ]]; do
	echo "[$(date)] Bootup is not yet finished." >> $testlog
	sleep 2s
done

echo -e "\n\nTest Results:\n===============\n" >> $testlog

# run test
run_cmd 'sudo yum install sos -y'
run_cmd 'sudo sosreport -a --batch'
run_cmd 'sudo cp $(ls -tr /var/tmp/sosreport*.tar.xz | tail -n 1) $HOME/workspace/log/'

exit 0

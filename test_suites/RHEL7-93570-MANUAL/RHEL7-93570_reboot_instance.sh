#!/bin/bash

set -e	# exit when error occurred

host=
pem=/home/cheshi/.pem/c5-test-cheshi.pem
inst_id=i-08578083695158a9a

#log=./RHEL7-93570_reboot_instance.log

function get_dns_by_instid()
{
	# $1 - Instance ID
	# output: $host

	host=$(aws ec2 describe-instances --instance-ids $1 --query 'Reservations[].Instances[].PublicDnsName' --output text)
}

function wait_instance_stat()
{
	if [ "$1" = "running" ] || [ "$1" = "stopped" ]; then
		target_state=$1
	else
		sleep 60s && echo "** Waited 60 seconds for unknown status \"$1\" **"
		return
	fi

	round=0
	state=""
	until [ "$state" = "$target_state" ] || [[ $round -gt 60 ]]; do
		let "round=round+1"
		state=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[].Instances[].State.Name' | sed -n 's/.*"\(.*\)".*/\1/p')
		echo "** $(date +"%Y-%m-%d %H:%M:%S") * wait \"$state\" becomes \"$target_state\" **"
		sleep 3s
	done
}


for i in {1..200}; do
	echo -e "\nReboot times: $i\n"

	echo -e "Stopping instance..."
	aws ec2 stop-instances --instance-ids $inst_id
	wait_instance_stat "stopped"

	echo -e "Starting instance..."
	aws ec2 start-instances --instance-ids $inst_id
	wait_instance_stat "running"

	echo -e "Wait another 30s..." && sleep 30s

	echo -e "Run test on instance..."
	get_dns_by_instid $inst_id
	echo "InstID: $inst_id PEM: $pem UserName: ec2-user Host: $host"
	ssh -o StrictHostKeyChecking=no -i $pem -l ec2-user $host "sudo systemctl status kdump &>/dev/null || sudo sudo kdumpctl restart"	# Workaround for kdump bug
	ssh -o StrictHostKeyChecking=no -i $pem -l ec2-user $host "~/inner_check.sh; cat ~/inner_check.log"
done

exit 0


#!/bin/bash

set -e	# exit when error occurred

host=
pem=/home/cheshi/.pem/c5-test-cheshi.pem
#inst_id=i-071e4c7bc06e7c7d8
#inst_id=i-0cc7d1919ebc15fd2	# cheshi-ebs-rhel74-i-0cc7d1919ebc15fd2
#inst_id=i-071e4c7bc06e7c7d8	# cheshi-ebs-rhel75-i-071e4c7bc06e7c7d8
#inst_id=i-059d2dc233b43ef3b	# cheshi-ebs-amzn2-i-059d2dc233b43ef3b
inst_id=i-0699913e427968c0b	# cheshi-ebs-rhel75-latest
vol1_id=vol-088ec5291a53df1f4
vol2_id=vol-057e2edefb7d83d16
vol3_id=vol-0b5656ce74a028731
vol4_id=vol-0e898fdc9306e8ca7

function get_dns_by_instid()
{
	# $1 - Instance ID
	# output: $host

	host=$(aws ec2 describe-instances --instance-ids $1 --query 'Reservations[].Instances[].PublicDnsName' --output text)
}

function guest_exec()
{
	echo "InstID: $inst_id PEM: $pem UserName: ec2-user Host: $host"
	ssh -o StrictHostKeyChecking=no -i $pem -l ec2-user $host "$@"
}

function wait_volume_stat()
{
	if [ "$1" = "available" ] || [ "$1" = "attached" ]; then
		stat=$1
	else
		sleep 60s && echo "** Waited 60 seconds for unknown status \"$1\" **"
		return
	fi

	round=0
	count=0
	until [[ $count -eq 4 ]] || [[ $round -gt 3000 ]]; do
                let "round=round+1"
                count=$(aws ec2 describe-volumes --volume-ids $vol1_id $vol2_id $vol3_id $vol4_id | grep $stat | wc -l)
                echo "** $(date +"%Y-%m-%d %H:%M:%S") * \"$stat\" ($count of 4) **"
                sleep 1s
	done
}


# Main
get_dns_by_instid $inst_id

for i in {1..20}; do
	echo -e "\nRound times: $i"

	# Attach Volume
	echo -e "\nAttaching..."
	aws ec2 attach-volume --volume-id $vol1_id --instance-id $inst_id --device /dev/sdf
	aws ec2 attach-volume --volume-id $vol2_id --instance-id $inst_id --device /dev/sdg
	aws ec2 attach-volume --volume-id $vol3_id --instance-id $inst_id --device /dev/sdh
	aws ec2 attach-volume --volume-id $vol4_id --instance-id $inst_id --device /dev/sdi
	wait_volume_stat "attached"

	echo -e "\nMounting..."
	#guest_exec 'for i in {f,g,h,i}; do sudo mkdir -p /mnt/$i; sudo mount /dev/xvd$i /mnt/$i; done && lsblk'
	guest_exec 'for i in {1,2,3,4}; do sudo mkdir -p /mnt/nvme${i}n1; sudo mount /dev/nvme${i}n1 /mnt/nvme${i}n1; done && lsblk'
	sleep 2s

	echo -e "\nUmounting..."
	#guest_exec 'for i in {f,g,h,i}; do sudo umount /dev/xvd$i; done && lsblk'
	guest_exec 'for i in {1,2,3,4}; do sudo umount /dev/nvme${i}n1; done && lsblk'

	# Detach Volume
	echo -e "\nDetaching..."
	aws ec2 detach-volume --volume-id $vol1_id --instance-id $inst_id
	aws ec2 detach-volume --volume-id $vol2_id --instance-id $inst_id
	aws ec2 detach-volume --volume-id $vol3_id --instance-id $inst_id
	aws ec2 detach-volume --volume-id $vol4_id --instance-id $inst_id
	wait_volume_stat "available"
done

exit 0


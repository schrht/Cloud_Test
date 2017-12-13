#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

inst_type=$(ec2-metadata -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
logfile=~/workspace/log/result_${inst_type}_${time_stamp}.log

# log the informaiton
show_info.sh >> $logfile 2>&1

# perform this test
echo -e "\n\nTest Results:\n===============\n" >> $logfile

function run_cmd(){
        # $1: Command

        echo -e "\n$ $1" >> $logfile
        eval $1 >> $logfile 2>&1
}

nvme_list=$(lsblk -d -o NAME | grep nvme)
if [ -z "$nvme_list" ]; then
	echo "Error: No NVMe device was found, test failed!" >> $logfile
else
	for device in $nvme_list; do
		echo -e "\nTRIM support? (discard_max_bytes != 0):\n" >> $logfile
		run_cmd "sudo grep \"^\" /sys/block/$device/queue/discard_max_bytes"

		echo -e "\nCreate file system on this device:\n" >> $logfile
		run_cmd "sudo mkfs.ext4 /dev/$device"

		echo -e "\nMount it and make sure trim successfully:\n" >> $logfile
		run_cmd "sudo mkdir -p /mnt/$device"
		run_cmd "sudo mount -t ext4 -o discard /dev/$device /mnt/$device"
		run_cmd "sudo fstrim /mnt/$device -v"
		run_cmd "sudo umount /dev/$device"
	done
fi

# teardown
teardown.sh

exit 0


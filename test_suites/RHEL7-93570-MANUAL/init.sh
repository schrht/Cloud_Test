#!/bin/bash

volume_list="/dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1"

for volume in $volume_list; do
	unset no_fs
	sudo parted $volume print 2>&1 | grep -q "unrecognised" && no_fs="yes"

	if [ "$no_fs" = "yes" ]; then
		echo -e "\ncreating fs for $volume ..."
		sudo mkfs -t xfs $volume
	fi
done


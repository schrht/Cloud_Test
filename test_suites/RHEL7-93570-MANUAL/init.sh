#!/bin/bash

# protect
[ "$(whoami)" != "ec2-user" ] && echo "AWS instance only" && exit 1

# detect volumes
lsblk | grep -q xvd && volume_mode="xvd" || volume_mode="nvme"

if [ "$volume_mode" = "nvme" ]; then
	# Support standard volume type
	volume_list="/dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1 /dev/nvme5n1"
else
	# Support standard volume type
	volume_list="/dev/xvdf /dev/xvdg /dev/xvdh /dev/xvdi /dev/xvdj"
fi

# do init
for volume in $volume_list; do
	unset no_fs
	sudo parted $volume print 2>&1 | grep -q "unrecognised" && no_fs="yes"

	if [ "$no_fs" = "yes" ]; then
		echo -e "\nCreating fs for $volume ..."
		sudo mkfs -t xfs $volume
	fi
done

exit 0


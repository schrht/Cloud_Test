#!/bin/bash

[ "$(whoami)" != "ec2-user" ] && echo "AWS instance only" && exit 1

# log name
log=~/inner_check.log

# print block info
date > $log
lsblk >> $log

# detect volumes
lsblk | grep -q xvd && volume_mode="xvd" || volume_mode="nvme"

if [ "$volume_mode" = "nvme" ]; then
	for i in {1,2,3,4,5}; do	# Support standard volume type

		# test file
		test_file=/mnt/nvme${i}n1/test-nvme${i}n1.txt
		echo -e "\n$(date)\nTest file: $test_file\n" >> $log

		# mount volume
		sudo mkdir -p /mnt/nvme${i}n1
		sudo mount /dev/nvme${i}n1 /mnt/nvme${i}n1 && echo "Mount Success." >> $log || echo "Mount Failed." >> $log

		# create
		sudo touch $test_file && echo "Create Success." >> $log || echo "Create Failed." >> $log

		# chmod
		sudo chmod 777 $test_file && echo "Chmod Success." >> $log || echo "Chmod Failed." >> $log

		# write
		echo "WRITE TEST" > $test_file && echo "Write Success." >> $log || echo "Write Failed." >> $log

		# rename
		sudo mv $test_file ${test_file}.new && echo "Rename Success." >> $log || echo "Rename Failed." >> $log

		# copy
		sudo cp ${test_file}.new $test_file && echo "Copy Success." >> $log || echo "Copy Failed." >> $log

		# dd-in
		sudo dd if=$test_file of=${test_file}.dd && echo "DD-in Success." >> $log || echo "DD-in Failed." >> $log

		# dd-out
		sudo dd if=${test_file}.dd of=$test_file && echo "DD-out Success." >> $log || echo "DD-out Failed." >> $log

		# read 
		sudo grep -q "WRITE TEST" $test_file && echo "Read Success." >> $log || echo "Read Failed." >> $log

		# delete
		sudo rm -f ${test_file}* && echo "Delete Success." >> $log || echo "Delete Failed." >> $log

		# umount volume
		sudo umount /dev/nvme${i}n1 && echo "Umount Success." >> $log || echo "Umount Failed." >> $log
	done

fi

if [ "$volume_mode" = "xvd" ]; then
	for i in {f,g,h,i,j}; do		# Support standard volume type
		sudo mount /dev/xvd$i /mnt/$i
		sudo uptime >> /mnt/$i/time-$i.txt
		sudo cat /mnt/$i/time-$i.txt > /mnt/$i/time-$i.test && sudo rm -f /mnt/$i/time-$i.test && echo "=====OK=====" >> $log
	done
fi

echo -e "\n\n" >> $log

exit 0


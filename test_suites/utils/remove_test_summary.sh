#!/bin/bash

# Description:
# This script is used to remove the "Test Summary" section from the log files.
#
# Usage:
# 1. `cd` into the log folder
# 2. run this script
# 3. get commands from file "./todo.cmd"
# ** double check the commands before running.

todofile="./todo.cmd"

echo "### Be aware of what you are doing, double check the commands before running!! ###" | tee $todofile

filelist=$(ls ./*.log)
for file in $filelist; do

	# Get offset
	pos=$(grep -n "Test Summary:" $file | cut -d: -f1)

	echo "file name is: \"$file\" and the offset is: $((pos-1))"

	echo "cp $file ${file}.bak && sed -i -n \"1,$((pos-1))p\" $file" >> $todofile
done

echo "Please review and run the commands in \"$todofile\"."

exit 0


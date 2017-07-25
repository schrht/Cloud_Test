#!/bin/bash

# Description:
# This script is used to summary test results.
# You can run it in a log folder or specify a folder for it.

if [ "$1" = "-r" ] || [ "$1" = "--raw" ]; then
	raw_output=1
	shift
fi

if [ "$1" = "" ]; then
	path=.
else
	path=$1
fi

tmplog=$(mktemp)

filelist=$(ls $path/*.log) || exit 1

for file in $filelist; do
	grep "^\*\*" $file >> $tmplog
done

# sort reports
sort -u $tmplog > $tmplog.sort && mv $tmplog.sort $tmplog

# get and remove title
title=$(grep "^\*\*.*VMSize" $tmplog)
grep -v "^\*\*.*VMSize" $tmplog > $tmplog.notitle && mv $tmplog.notitle $tmplog

if [ ${raw_output:-0} = 1 ]; then
	# raw output
	echo "$title" | awk '{for(i=2; i<=NF; i++) printf $i","; printf "\n"}'
	cat $tmplog | awk '{for(i=2; i<=NF; i++) printf $i","; printf "\n"}'
else
	# original output
	echo "$title"
	cat $tmplog
fi

exit 0


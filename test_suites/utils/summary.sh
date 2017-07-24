#!/bin/bash

# Description:
# This script is used to summary test results.
# You can run it in a log folder or specify a folder for it.

if [ "$1" = "" ]; then
	path=.
else
	path=$1
fi


if [ "$(ls $path/*.log | wc -l)" -gt "1" ]; then
	grep "^\*\*" $path/*.log | awk -F ':' '{print $2}' | sort -r -u
else
	grep "^\*\*" $path/*.log | sort -r -u
fi

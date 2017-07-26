#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# This script is used to tell the cloud type

if [ "" = "" ]; then
	echo "aws"
else
	echo "azure"
fi

exit 0


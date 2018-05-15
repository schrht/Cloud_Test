#!/bin/bash

#sed 's/"IMAGE_ID".*$/"IMAGE_ID": "ami-11111111",/' ./configure.json

ami_list="ami-679eea1f ami-1b91e563 ami-a891e5d0 ami-0470047c ami-317a0e49 ami-949febec ami-f698ec8e ami-1e86f266"

for ami in $ami_list; do
	echo "Current AMI ID: $ami"
	sed -i "s/\"IMAGE_ID\".*$/\"IMAGE_ID\": \"$ami\",/" ./configure.json
	./run.py
done

return 0


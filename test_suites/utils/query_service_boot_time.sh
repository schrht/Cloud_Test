#!/bin/bash

if [ -z "$1" ]; then
	echo -e "\nUsage:   $0 <service_name>\nExample: $0 kdump.service\n"
	exit 1
else
	service="$1"
fi

filelist=$(ls boot*.log)

# Print summary title
printf "** %-12s %-10s %-20s\n" VMSize Method $service

for file in $filelist; do
	vmsize=$(echo $file | cut -d_ -f3)
	method=$(echo $file | cut -d_ -f4)
	
	# TARGET: "        26.251s kdump.service"
	boot_time=$(grep " $service" $file | awk '{print $1}')

	# Print summary tuples
	printf "** %-12s %-10s %-20s\n" $vmsize $method $boot_time
done

exit 0


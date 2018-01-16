#!/usr/bin/bash

function check()
{
	echo -e "\n\$ $@ \n"
	eval $@
}

if [[ "$PWD" =~ "RHEL7-87117" ]]; then
	check grep "modinfo ena" -A 100 result_*
	check grep "^version:" result_*
	check tail -n 3 aws_check_*
	check tail -n 5 iperf3_client_*
	check grep -w ena dmesg_* | grep -v "irq.*for MSI/MSI-X" | grep -v "Elastic Network Adapter (ENA)" | grep -v "version: " | grep -v "creating.*io queues"
fi

if [[ "$PWD" =~ "RHEL7-87119" ]]; then
	check grep "modinfo ixgbevf" -A 100 result_*
	check tail -n 6 aws_check_*
	check tail -n 5 iperf3_client_*
fi

if [[ "$PWD" =~ "RHEL7-87122" ]]; then
	check 'grep Non-Volatile result_*'
	check 'grep -e "nvme list" -e "^Node" -e "^/dev/.*Amazon EC2 NVMe Instance Storage" result_*'
	check 'grep -e "nvme read" -e "nvme write" -A 3 result_*'
fi

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

if [[ "$PWD" =~ "RHEL7-87124" ]]; then
	check 'grep "rpm -qa | grep stress" -A 2 result_*'

	echo -e "\nCHECKPOINTS:"
	echo -e "When \"-c 2\"   : Avg_MHz:low,  Bzy_MHz>TSC_MHz, CPU%c1:<10, CPU%c6:high"
	echo -e "When \"-c all\" : Avg_MHz:high, Bzy_MHz>TSC_MHz, CPU%c1:low, CPU%c6:low"
	check 'grep -e "turbostat stress" -A 6 result_1_* | grep -v "stress: info:"'

	echo -e "\nCHECKPOINTS:"
	echo -e "First Item : Avg_MHz:low, Bzy_MHz>TSC_MHz, CPU%c1:~100%, CPU%c6:low"
	echo -e "Second Item: Avg_MHz:low, Bzy_MHz=TSC_MHz, CPU%c1:~100%, CPU%c6:low"
	check 'grep -e "turbostat stress" -A 6 result_2_* | grep -v "stress: info:"'
fi

if [[ "$PWD" =~ "RHEL7-87306" ]]; then
	check 'grep "^\*.*nproc" resource_validation_*'
	check 'grep "^\*\* " resource_validation_*'
	check 'grep "virt-what" -A 10 resource_validation_*'
fi

if [[ "$PWD" =~ "RHEL7-87311" ]]; then
	check 'grep "grep.*discard_max_bytes" -A 2 result_*'
	check 'grep -e "^Allocating" -e "^Writing" -e "^Creating" -B 1 result_*'
	check 'grep "fstrim /mnt/.*" -A 2 result_*'
fi

exit 0


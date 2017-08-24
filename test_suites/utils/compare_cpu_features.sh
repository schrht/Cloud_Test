#!/bin/bash

function collect(){
	# $1: the folder with logs

	[ ! -d "$1" ] && echo "This function requires a folder as input." && return

	filelist=$(ls $1/*.log)
	for logfile in $filelist; do
		vmsize=$(grep instance-type: $logfile | awk '{print $2}')

		system="UNKNOWN"
		grep "Ubuntu" $logfile >/dev/null 2>&1
                [ "$?" = "0" ] && system="UBTL"
		grep "Amazon Linux" $logfile >/dev/null 2>&1
		[ "$?" = "0" ] && system="AMZN"
		grep "Red Hat Enterprise Linux" $logfile >/dev/null 2>&1
		[ "$?" = "0" ] && system="RHEL"

		cpuflags=$(grep "flags\s*:" $logfile | sort -u | awk -F ':' '{print $2}')

		#echo -e "[$vmsize $system] $cpuflags"
		echo -e "[$vmsize] $cpuflags"
	done
}

rhel_summary=$(mktemp) && echo "Red Hat Enterprise Linux" >> $rhel_summary
amzn_summary=$(mktemp) && echo "Amazon Linux" >> $amzn_summary

collect ./RHEL7-87306rht >> $rhel_summary
collect ./RHEL7-87306amz >> $amzn_summary

vimdiff $rhel_summary $amzn_summary
diff $rhel_summary $amzn_summary > compare_cpu_features.report

rm $rhel_summary $amzn_summary

exit 0


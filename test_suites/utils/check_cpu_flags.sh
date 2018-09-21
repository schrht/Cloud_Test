#!/bin/bash

# History:
# v1.0  2018-06-26  charles.shih  init version
# v1.1  2018-09-21  charles.shih  Add description in help message

if [ "$#" -lt 1 ]; then
	echo -e "\nUsage:"
	echo -e "$0 <RHEL7-87306/93100 log files>"
	echo -e "\nDescription:"
	echo -e "It will analyse the Linux vendor from log and \
create './check_cpu_flags.report' which contains the reports."
	echo -e "\nExample:"
	echo -e "$0 \$(find ./ -type f -name 'resource_validation_*.log')"
	echo -e "\nUseful commands:"
	echo -e "cd ./check_cpu_flags.report"
	echo -e "diff amzn2 rhel7 | grep -i -w only"
	echo -e "diff amzn2 rhel7 | grep \"<\" | sort -u"
	echo -e "diff amzn2 rhel7 | grep \">\" | sort -u"

	exit 1
else
	files=$@
fi

for file in $files;
do
	# get system
	line=$(grep -m 1 "uname -a" -A 2 $file | tail -n 1)
	[[ "$line" =~ "el7" ]] && system="rhel7"
	[[ "$line" =~ "amzn2" ]] && system="amzn2"

	# get instance type
	inst_type=$(grep -m 1 "^instance-type:" $file | cut -d ' ' -f 2)

	# set path and log name
	path="./check_cpu_flags.report/${system:=unknown}"
	log="${inst_type:=unknown}.cpuflags"

	mkdir -p $path || exit 1
	
	# get flags
	grep -m 1 "^flags" $file > ./$$.temp
       	sed -i -e 's/^flags.*: //' -e 's/ /\n/g' ./$$.temp
	sort $$.temp > $path/$log
	rm -f $$.temp
done

exit 0


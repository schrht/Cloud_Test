#!/bin/bash


if [ "$#" -lt 1 ]; then
	echo -e "\nUsage: $0 <RHEL7-87306 logs>\n"
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


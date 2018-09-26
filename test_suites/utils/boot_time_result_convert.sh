#!/bin/bash

function convert2sec() {
	# $@ : the STRING in time format
	#      1min54s
	#      1min245ms
	# Description:
	#      It takes a time STRING, convert and echo as a value in seconds

	[[ "$@" != [0-9]* ]] && echo "$@" && return

	remaining="$@"

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w min
	if [ $? = 0 ]; then
		mstr=${remaining%%min*}
		remaining=${remaining#*min}
	fi

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w s
	if [ $? = 0 ]; then
		sstr=${remaining%%s*}
		remaining=${remaining#*s}
	fi

	echo $remaining | tr -c "[:alpha:]" " " | grep -q -i -w ms
	if [ $? = 0 ]; then
		msstr=${remaining%%ms*}
	fi

	echo ${mstr:=0} ${sstr:=0} ${msstr:=0} | awk '{print $1*60+$2+$3/1000}'
}

if [ $# -lt 1 ]; then
	echo -e "\nUsage: $0 <file with boot time results in raw format>\n"
	exit 1
fi

content=$(cat $1)

for line in $content; do
	#echo $line
	f1=$(echo $line | cut -d ',' -f 1)
	f2=$(echo $line | cut -d ',' -f 2)
	f3=$(echo $line | cut -d ',' -f 3)
	f4=$(echo $line | cut -d ',' -f 4)
	f5=$(echo $line | cut -d ',' -f 5)
	f6=$(echo $line | cut -d ',' -f 6)
	echo $f1,$f2,$(convert2sec $f3),$(convert2sec $f4),$(convert2sec $f5),$(convert2sec $f6)
done

#convert2sec "$1"

exit 0


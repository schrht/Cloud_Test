#!/bin/bash

# Description:
# This script is used to get all the metadata in cloud instance.
#
# History:
# v1.0   2018-08-28  charles.shih  Initial version

debug() { [ ! -z $DEBUG ] && echo "DEBUGINFO: $@"; }

die() { echo "ERROR: Line $@"; exit 1; }

determine_baseurl() {
	# Description: Try to determine the baseurl
	# Update: $baseurl
	# Return: 0 - success / 1 - failed

	debug "Enter func determine_baseurl"
	
	list="http://169.254.169.254/latest/meta-data/"			# AWS
	list="$list http://169.254.169.254/meta-data/"			# Azure
	list="$list http://100.100.100.200/latest/meta-data/"	# Aliyun

	for url in $list; do
		x=$(curl --connect-timeout 2 $url 2>/dev/null)
		[ $? = 0 ] && [[ ! "$x" =~ "404 - Not Found" ]] && break || unset url
	done

	[ ! -z $url ] && baseurl="$url" && return 0 || return 1
}

display() {
	# Description: Display the metadata
	# Inputs:
	#   $1 - URL of the metadata
	# Outputs:
	#   The URL and its content
	# Return: None

	debug "Enter func display, args = $@"

	echo $1
	x=$(curl --connect-timeout 10 $1 2>/dev/null)
	[ $? != 0 ] && die "$LINENO: curl failed with code=$?."
	[[ ! "$x" =~ "404 - Not Found" ]] && echo "$x" || echo "404 - Not Found"

	return
}

traverse() {
	# Description: Traverse the metadata
	# Return: 0 - success / 1 - failed

	debug "Enter func traverse, args = $@"

	local root=$1
	x=$(curl --connect-timeout 10 $root 2>/dev/null)
	[ $? != 0 ] && die "$LINENO: curl failed with code=$?."
	[[ "$x" =~ "404 - Not Found" ]] && die "$LINENO: Err 404 - Not Found."

	debug "root = $root; x = $x"

	for child in $x; do
		#local child=$node

		# Deal with public-keys, example: "0=cheshi" -> "0/"
		[[ $root = *public-keys* ]] && [[ $child = *=* ]] && child="${child%%=*}/"

		if [[ $child = */ ]]; then
			# Non-leaf, continue traverse
			traverse ${root}${child}
		else
			# Leaf, display metadata
			display ${root}${child}
		fi
	done
	return 0
}

# Main
#DEBUG=yes
determine_baseurl || die "$LINENO: Unable to determine baseurl."
traverse $baseurl

exit 0

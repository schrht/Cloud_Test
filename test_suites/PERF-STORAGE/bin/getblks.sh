#!/bin/bash

# Description:
#   Get the name of block devices from guest on AWS.
#
# Parameters:
#   -h : help
#   -r : show the root device where '/' mounted
#   -e: show EBS devices
#   -l: show local devices
#   -s <separator>: show list with a specified separator
#
# History:
#   v1.0     2019-10-22  charles.shih  Initial version
#   v1.0.1   2019-10-22  charles.shih  Bugfix for a parameter issue

function get_root_device() {
	# This function looks up and returns the name of root device.
	# Inputs:
	#     None
	# Outputs:
	#     root_dev: The name of root device

	local ret=$(sudo mount / 2>&1)
	[[ "$ret" =~ "already mounted on" ]] || exit 1
	local part_name=$(echo $ret | awk '{print $3}')
	[[ "$part_name" =~ "nvme" ]] || exit 1
	root_dev=${part_name%p*}
}

function get_full_list() {
	# This function looks up and returns all the names of block device.
	# Inputs:
	#     None
	# Outputs:
	#     full_list: The names of block device

	full_list=$(lsblk -p -d | awk '{print $1}' | grep -v NAME)
}

function get_local_list() {
	# This function returns all the names of local block device.
	# Inputs:
	#     full_list: The names of block device
	#     root_dev: The name of root device
	# Outputs:
	#     loc_list: The names of block device

	[ -z "$root_dev" ] && exit 1

	local list=()

	for item in $full_list; do
		[ "$item" = "$root_dev" ] && break
		list=(${list[@]} $item)
	done

	loc_list=${list[@]}
}

function get_ebs_list() {
	# This function returns all the names of EBS block device.
	# Inputs:
	#     full_list: The names of block device
	#     root_dev: The name of root device
	# Outputs:
	#     ebs_list: The names of block device

	[ -z "$root_dev" ] && exit 1

	local list=()
	local switch=off

	for item in $full_list; do
		[ "$switch" = "on" ] && list=(${list[@]} $item)
		[ "$item" = "$root_dev" ] && switch=on
	done

	ebs_list=${list[@]}
}

function show_help() {
	echo -e "$0 [-h] [-r] [-e] [-l] [-s <separator>]" >&2
	echo -e "-h: help" >&2
	echo -e "-r: show the root device where '/' mounted" >&2
	echo -e "-e: show EBS devices" >&2
	echo -e "-l: show local devices" >&2
	echo -e "-s <separator>: show list with a specified separator" >&2
}

function show() {
	# This function show the items in list.
	# Inputs:
	#     The list of block device name
	#     separator: the separator for items

	if [ -z "$separator" ]; then
		echo $@
	else
		echo $@ | column -t -o "$separator"
	fi
}

# Main

[ $# -eq 0 ] && show_help && exit 1

while getopts "h?rels:" opt; do
	case "$opt" in
	h | \?)
		show_help
		exit 1
		;;
	r)
		show_root=1
		;;
	e)
		show_ebs=1
		;;
	l)
		show_loc=1
		;;
	s)
		separator="$OPTARG"
		;;
	esac
done

shift $((OPTIND - 1))
[ "${1:-}" = "--" ] && shift

get_root_device
get_full_list
get_ebs_list
get_local_list

[ ! -z "$show_loc" ] && show $loc_list
[ ! -z "$show_root" ] && show $root_dev
[ ! -z "$show_ebs" ] && show $ebs_list

exit 0

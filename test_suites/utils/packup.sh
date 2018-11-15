#!/bin/bash

# Description:
# Packing up the log files in RHEL7-93100 result folder.
#
# History:
# v1.0.0  2018-11-15  charles.shih  Init version

stuff=$(ls)

function do_pack_up() {
	# $1: the label
	label="$1"
	if [[ "$stuff" =~ "${label}_" ]]; then
		echo "Packing up label: $label"
		mkdir -p $label
		mv ${label}_* $label
	fi
}

do_pack_up vm_check
do_pack_up sos_report 
do_pack_up resource_validation 
do_pack_up full_metadata
do_pack_up dmesg
do_pack_up boot_time


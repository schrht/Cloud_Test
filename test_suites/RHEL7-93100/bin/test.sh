#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

# sub-tests
label=$1  # label: create, reboot...

test_boot_time.sh $label
test_resource_information.sh $label

vm_check.sh
sos_report.sh

# teardown
teardown.sh

exit 0


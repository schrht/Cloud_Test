#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

# sub-tests
label=$1  # label: create, reboot...

general_test.sh

test_boot_time.sh $label
test_resource_information.sh $label

# teardown
teardown.sh

exit 0

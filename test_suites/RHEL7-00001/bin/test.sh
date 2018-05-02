#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# setup
setup.sh

# sub-tests
resource_validation.sh
boot_time.sh

# teardown
teardown.sh

exit 0

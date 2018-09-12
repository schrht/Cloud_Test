#!/bin/bash

# This script should be run in container. It will help the user do some
# container based configuration.

die() { echo "$@"; exit 1; }

# Basic check
mount | grep -q /data || die "ERROR: The data volume has not been mounted."
[ -d "/data/Cloud_Test" ] || die "ERROR: /data/Cloud_Test can not be found."

# Configure Cloud_Test
cat > ~/.ec2cfg.json <<EOF
{
    "DEFAULT_REGION": "us-west-2",
    "KEY_NAME": "cheshi-docker",

    "DEFAULT_USER_NAME": "ec2-user",
    "PEM": {
        "us-west-2": "/data/cheshi-docker.pem"
    },

    "SECONDARY_VOLUME_DEVICE": "/dev/xvdf"
}
EOF

sed -i 's#.*"LOG_SAVE_PATH".*#    "LOG_SAVE_PATH": "/data/cloud_test_outputs/",#' /data/Cloud_Test/test_suites/default_configure.json

exit 0


#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# Please note:
# The commands in this script will be executed on every 
# instance before test steps. You can use this script to 
# do some general configuration, such as configure the 
# yum repos or deal with something based on the image.

# Common Configuration & Setup
sudo yum-config-manager --disable rhel7u4-debug >/dev/null 2>&1

exit 0


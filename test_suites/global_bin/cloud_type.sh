#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

# This script is used to tell the cloud type

which virt-what 1> /dev/null 2> /dev/null
if [ $? != 0 ];then
    yum -y install virt-what 1> /dev/null 2> /dev/null
    if [ $? != 0 ];then
        echo "No repo enabled in YUM"
        exit 254
    fi
fi

platform=$(virt-what | head -n 1)

if [ ${platform}x == "hyperv"x ];then
    CLOUD_PLATFORM="azure"
elif [ ${platform}x == "xen"x ];then
    CLOUD_PLATFORM="aws"
else
    echo "This can only run in Azure/AWS!"
    exit 253
fi


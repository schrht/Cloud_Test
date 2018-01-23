#!/bin/bash

# Description:
# This script is used to upgarde RHEL with private compose.
#
# Details:
# http://blog.csdn.net/sch0120/article/details/73744504

if [ $# -lt 3 ]; then
	echo -e "\nUsage: $0 <pem file> <instance ip / hostname> <the baseurl to be placed in repo file>\n"
	exit 1
fi

pem=$1
instname=$2
baseurl=$3

repo_file=/tmp/rhel-debug.repo

cat << EOF > $repo_file
[rhel-debug]
name=rhel-debug
baseurl=$baseurl
enabled=1
gpgcheck=0
proxy=http://127.0.0.1:8080/
EOF

echo -e "\nThe content in repo file will be:"
cat $repo_file

function upload()
{
	# $1: file/directory to be uploaded
	# $2: remote path

	cmd="scp -i $pem -r $1 ec2-user@$instname:$2"

	echo -e "\n\$ $cmd"
	eval "$cmd"
}

function execute()
{
	# $1: command to be excuted

	cmd="ssh -R 8080:127.0.0.1:3128 -i $pem ec2-user@$instname '$1'"

	echo -e "\n\$ $cmd"
	eval "$cmd"
}

upload $repo_file '~' || exit 1
execute "sudo mv ~/rhel-debug.repo /etc/yum.repos.d/" || exit 1
execute "sudo yum-config-manager --enable rhel-debug" || exit 1
execute "sudo yum update -y" || exit 1
execute "sudo yum-config-manager --disable rhel-debug" || exit 1
#execute "echo '$(date) : $(uname -r)' | tee --append ~/update.log" || exit 1 # TODO: need bugfix here.
#execute "sudo reboot" || exit 1

rm -f $repo_file

exit 0


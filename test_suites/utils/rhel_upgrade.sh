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
remote_script=/tmp/do_upgrade.sh

cat << EOF > $repo_file
[rhel-debug]
name=rhel-debug
baseurl=$baseurl
enabled=1
gpgcheck=0
proxy=http://127.0.0.1:8080/
EOF

cat << EOF > $remote_script
#!/bin/bash

# setup repo
sudo mv ~/rhel-debug.repo /etc/yum.repos.d/

# enable repo
sudo yum-config-manager --enable rhel-debug

# do upgrade
sudo yum update -y

# install specific packages
sudo yum install -y kernel-tools
sudo yum install -y kernel-devel
sudo yum install -y gcc
sudo yum install -y pciutils nvme-cli
sudo yum install -y wget
sudo yum install -y virt-what
sudo yum install -y libaio-devel

# disable repo
sudo yum-config-manager --disable rhel-debug

# save to version.log
date && uname -r && echo
echo "\$(date) : \$(uname -r)" >> ~/version.log

# do some check
echo "Check installed packages:"
rpm -q kernel-tools 	|| result="failed"
rpm -q gcc 		|| result="failed"
rpm -q pciutils 	|| result="failed"
rpm -q nvme-cli 	|| result="failed"
rpm -q wget 		|| result="failed"
rpm -q virt-what 	|| result="failed"
rpm -q libaio-devel 	|| result="failed"

if [ "\$result" = "failed" ]; then
	echo -e "\nCheck failed!\n"
	exit 1
else
	echo -e "\nCheck passed!\n"
fi

# reboot the system
read -t 20 -n 1 -p "Skip the system reboot for this moment? [y/n] " answer
if [ "\$answer" = "y" ]; then
	echo -e "\nPlease reboot the system later to take effect."
else
	echo -e "\nRebooting the system..."
	sudo reboot
fi

exit 0
EOF

# confirm the repo file content
echo -e "\nThe content of the repo file will be:"
echo "---------------"
cat $repo_file
echo "---------------"

read -n 1 -p "Do you want to continue? [y/n] " answer

if [ "$answer" = "y" ]; then
	# upload files to the instance
	scp -i $pem $repo_file $remote_script ec2-user@$instname:~

	# upgrade the instance
	ssh -R 8080:127.0.0.1:3128 -i $pem ec2-user@$instname "chmod 755 ~/do_upgrade.sh && ~/do_upgrade.sh 2>&1 | tee ~/do_upgrade.log"
else
	echo -e "\nAborted."
fi

# remove the temp files
rm -f $repo_file $remote_script

exit 0


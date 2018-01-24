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

# disable repo
sudo yum-config-manager --disable rhel-debug

# save to version.log
date && uname -r && echo
echo "\$(date) : \$(uname -r)" >> ~/version.log

# reboot the system
read -t 20 -n 1 -p "Do you want to skip the system reboot? [y/n] " answer
if [ "\$answer" = "y" ]; then
	echo -e "\nPlease reboot the system manually to take effect."
else
	sudo reboot
fi

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


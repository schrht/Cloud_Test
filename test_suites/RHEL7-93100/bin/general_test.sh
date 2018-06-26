#!/bin/bash

PATH=~/workspace/bin:/usr/sbin:/usr/local/bin:$PATH

inst_type=$(metadata.sh -t | awk '{print $2}')
time_stamp=$(timestamp.sh)
base="$HOME/workspace/log/general_test_${inst_type}_${time_stamp}"
mkdir -p $base
readme=$base/readme.txt

# perform this test
function run_cmd(){
	# $1: Command to be executed
	# $2: The filename where log to be saved (optional)

	if [ -z "$2" ]; then
		sublog=$base/$(echo $1 | tr -c "[:alpha:][:digit:]" "_").log
	else
		sublog=$base/$2
	fi

	echo -e "\ncmd> $1" >> $readme
	echo -e "log> $sublog" >> $readme
	eval $1 >> $sublog 2>&1

	return $?
}

# Waiting for Bootup finished
while [[ "$(sudo systemd-analyze time 2>&1)" =~ "Bootup is not yet finished" ]]; do
	echo "[$(date)] Bootup is not yet finished." >> $readme
	sleep 2s
done

echo -e "\n\nInstallation:\n===============\n" >> $readme

# install
sudo yum install sysstat -y &>> $readme

echo -e "\n\nTest Results:\n===============\n" >> $readme

# boot
run_cmd 'sudo systemd-analyze time'
run_cmd 'sudo systemd-analyze blame'
run_cmd 'sudo systemd-analyze critical-chain'
run_cmd 'sudo systemd-analyze dot'

# system
run_cmd 'cat /proc/version'
run_cmd 'uname -r'
run_cmd 'uanme -a'
run_cmd 'lsb_release -a'
run_cmd 'cat /etc/redhat-release'
run_cmd 'cat /etc/issue'

# bios and hardware
run_cmd 'sudo dmidecode -t bios'
run_cmd 'lspci'

# package
run_cmd 'sudo rpm -qa'

# kernel
run_cmd 'lsmod'
run_cmd 'date'
run_cmd 'cat /proc/uptime'
run_cmd 'uptime'
run_cmd 'top -b -n 1'
run_cmd 'set'
run_cmd 'systemctl'
run_cmd 'vmstat 3 1'
run_cmd 'sudo vmstat -m'
run_cmd 'sudo vmstat -a'
run_cmd 'w'
run_cmd 'who'
run_cmd 'whoami'
run_cmd 'sudo ps -A'
run_cmd 'sudo ps -Al'
run_cmd 'sudo ps -AlF'
run_cmd 'sudo ps -AlFH'
run_cmd 'sudo ps -AlLm'
run_cmd 'sudo ps -ax'
run_cmd 'sudo ps -axu'
run_cmd 'sudo ps -ejH'
run_cmd 'sudo ps -axjf'
run_cmd 'sudo ps -eo euser,ruser,suser,fuser,f,comm,label'
run_cmd 'sudo ps -axZ'
run_cmd 'sudo ps -eM'
run_cmd 'sudo ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:14,comm'
run_cmd 'sudo ps -axo stat,euid,ruid,tty,tpgid,sess,pgrp,ppid,pid,pcpu,comm'
run_cmd 'sudo ps -eo pid,tt,user,fname,tmout,f,wchan'
run_cmd 'free'
run_cmd 'free -k'
run_cmd 'free -m'
run_cmd 'free -h'
run_cmd 'sudo cat /proc/meminfo'
run_cmd 'lscpu'
run_cmd 'sudo cat /proc/cpuinfo'
run_cmd 'mpstat -P ALL'
run_cmd 'sar -n DEV'
run_cmd 'iostat'
run_cmd 'netstat -tulpn'
run_cmd 'netstat -nat'
run_cmd 'ss -t -a'
run_cmd 'ss -u -a'
run_cmd 'ss -t -a -Z'
run_cmd 'sudo cat /proc/zoneinfo'
run_cmd 'sudo cat /proc/mounts'
run_cmd 'sudo cat /proc/interrupts'

# block
run_cmd 'lsblk'
run_cmd 'lsblk -p'
run_cmd 'lsblk -d'
run_cmd 'lsblk -d -p'
run_cmd 'df -k'
run_cmd 'fdisk -l'

# network
run_cmd 'ifconfig -a'
run_cmd 'ethtool eth0'
run_cmd 'sudo ip link'
run_cmd 'sudo ip address'
run_cmd 'sudo ip addrlabel'
run_cmd 'sudo ip route'
run_cmd 'sudo ip rule'
run_cmd 'sudo ip neigh'
run_cmd 'sudo ip ntable'
run_cmd 'sudo ip tunnel'
run_cmd 'sudo ip tuntap'
run_cmd 'sudo ip maddress'
run_cmd 'sudo ip mroute'
run_cmd 'sudo ip mrule'
run_cmd 'sudo ip xfrm'
run_cmd 'sudo ip netns'
run_cmd 'sudo ip l2tp'
run_cmd 'sudo ip fou'
run_cmd 'sudo ip macsec'
run_cmd 'sudo ip tcp_metrics'
run_cmd 'sudo ip token'
run_cmd 'sudo ip netconf'
run_cmd 'sudo ip ila'

exit 0

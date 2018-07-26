#!/bin/bash

# Description:
# This script is used to get general information in Linux OS by running varity of
# Linux commands. Some of them require super user permission, so this script should be
# running by root.
#
# History:
# v1.0  2018-06-26  charles.shih  Initial version
# v1.1  2018-07-10  charles.shih  Add commands for cloud-init and others
# v1.2  2018-07-12  charles.shih  Add commands lspci
# v1.3  2018-07-13  charles.shih  Remove command cat /proc/kmsg
# v2.0  2018-07-13  charles.shih  Support running on Non-AWS
# v2.1  2018-07-16  charles.shih  Remove command cat /proc/kpage*
# v2.2  2018-07-16  charles.shih  Add some commands for network and cloud-init
# v2.3  2018-07-20  charles.shih  Add some commands for network
# v2.4  2018-07-20  charles.shih  Add some command journalctl to get system log

# Notes:
# On AWS the default user is ec2-user and it is an sudoer without needing a password;
# On Azure and Aliyun the default user is root.

show_inst_type() {
	# AWS
	inst_type=$(curl http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
	[ ! -z "$inst_type" ] && echo $inst_type && return 0

	# Azure
	inst_type=$(curl http://169.254.169.254/meta-data/instance-type 2>/dev/null)
	[ ! -z "$inst_type" ] && echo $inst_type && return 0

	# To be supported
	return 1
}

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

# Start VM check
inst_type=$(show_inst_type)
time_stamp=$(date +%Y%m%d%H%M%S)
base="$HOME/workspace/log/vm_check_${inst_type:=unknown}_${time_stamp=random$$}"
mkdir -p $base
readme=$base/readme.txt

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
run_cmd 'sudo systemctl'

# system
run_cmd 'cat /proc/version'
run_cmd 'uname -r'
run_cmd 'uname -a'
run_cmd 'lsb_release -a'
run_cmd 'cat /etc/redhat-release'
run_cmd 'cat /etc/issue'

# bios and hardware
run_cmd 'sudo dmidecode -t bios'
run_cmd 'lspci'
run_cmd 'lspci -v'
run_cmd 'lspci -vv'
run_cmd 'lspci -vvv'

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
run_cmd 'sudo cat /var/log/messages'
run_cmd 'dmesg'
run_cmd 'dmesg -l emerg'
run_cmd 'dmesg -l alert'
run_cmd 'dmesg -l crit'
run_cmd 'dmesg -l err'
run_cmd 'dmesg -l warn'
run_cmd 'dmesg -l notice'
run_cmd 'dmesg -l info'
run_cmd 'dmesg -l debug'
run_cmd 'dmesg -f kern'
run_cmd 'dmesg -f user'
run_cmd 'dmesg -f mail'
run_cmd 'dmesg -f daemon'
run_cmd 'dmesg -f auth'
run_cmd 'dmesg -f syslog'
run_cmd 'dmesg -f lpr'
run_cmd 'dmesg -f news'
run_cmd 'journalctl'

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
run_cmd 'ethtool -a eth0'
run_cmd 'ethtool -c eth0'
run_cmd 'ethtool -g eth0'
run_cmd 'ethtool -k eth0'
run_cmd 'ethtool -n eth0'
run_cmd 'ethtool -T eth0'
run_cmd 'ethtool -x eth0'
run_cmd 'ethtool -P eth0'
run_cmd 'ethtool -l eth0'
run_cmd 'ethtool --show-priv-flags eth0'
run_cmd 'ethtool --show-eee eth0'
run_cmd 'ethtool --show-fec eth0'
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
run_cmd 'hostname'
run_cmd 'cat /etc/hostname'
run_cmd 'cat /etc/hosts'
run_cmd 'ping -c 1 8.8.8.8'
run_cmd 'ping6 -c 1 2001:4860:4860::8888'

# cloud-init
run_cmd 'sudo cat /var/log/cloud-init.log'
run_cmd 'sudo cat /var/log/cloud-init-output.log'
run_cmd 'sudo service cloud-init status'
run_cmd 'sudo service cloud-init-local status'
run_cmd 'sudo service cloud-config status'
run_cmd 'sudo service cloud-final status'
run_cmd 'systemctl status cloud-{init,init-local,config,final}'

# others
run_cmd 'sudo cat /proc/buddyinfo'
run_cmd 'sudo cat /proc/cgroups'
run_cmd 'sudo cat /proc/cmdline'
run_cmd 'sudo cat /proc/consoles'
run_cmd 'sudo cat /proc/crypto'
run_cmd 'sudo cat /proc/devices'
run_cmd 'sudo cat /proc/diskstats'
run_cmd 'sudo cat /proc/dma'
run_cmd 'sudo cat /proc/execdomains'
run_cmd 'sudo cat /proc/fb'
run_cmd 'sudo cat /proc/filesystems'
run_cmd 'sudo cat /proc/iomem'
run_cmd 'sudo cat /proc/ioports'
run_cmd 'sudo cat /proc/kallsyms'
run_cmd 'sudo cat /proc/keys'
run_cmd 'sudo cat /proc/key-users'
run_cmd 'sudo cat /proc/loadavg'
run_cmd 'sudo cat /proc/locks'
run_cmd 'sudo cat /proc/mdstat'
run_cmd 'sudo cat /proc/misc'
run_cmd 'sudo cat /proc/modules'
run_cmd 'sudo cat /proc/mtrr'
run_cmd 'sudo cat /proc/pagetypeinfo'
run_cmd 'sudo cat /proc/partitions'
run_cmd 'sudo cat /proc/sched_debug'
run_cmd 'sudo cat /proc/schedstat'
run_cmd 'sudo cat /proc/slabinfo'
run_cmd 'sudo cat /proc/softirqs'
run_cmd 'sudo cat /proc/stat'
run_cmd 'sudo cat /proc/swaps'
run_cmd 'sudo cat /proc/sysrq-trigger'
run_cmd 'sudo cat /proc/timer_list'
run_cmd 'sudo cat /proc/timer_stats'
run_cmd 'sudo cat /proc/vmallocinfo'
run_cmd 'sudo cat /proc/vmstat'

exit 0


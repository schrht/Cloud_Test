#!/usr/bin/env python
# -*- coding:utf-8 -*-

import sys
import time
import os
import random
import json

sys.path.append('..')
from cloud.ec2cli import create_instance
from cloud.ec2cli import run_shell_command_on_instance
from cloud.ec2cli import terminate_instance
from cloud.ec2cli import attach_volume_to_instance
from cloud.ec2cli import get_file_from_instance


def load_tscfg():
    '''load test suite configuration'''
    
    TSCFG_JSON_FILE = './testsuite_02_configuration.json'
    
    def byteify(input):
        '''Convert unicode to string for JSON.loads'''
        if isinstance(input, dict):
            return {byteify(key):byteify(value) for key,value in input.iteritems()}
        elif isinstance(input, list):
            return [byteify(element) for element in input]
        elif isinstance(input, unicode):
            return input.encode('utf-8')
        else:
            return input

    
    if not os.path.exists(TSCFG_JSON_FILE):
        default_tscfg = {}
        default_tscfg['REGION']='us-east-1'
        default_tscfg['IMAGE_ID']='ami-5bc4964d'
        default_tscfg['SUBNET_ID']='subnet-73f7162b'
        default_tscfg['SECURITY_GROUP_IDS']=('sg-aef4fad0',)
        default_tscfg['INSTANCE_TYPE_LIST']=('t2.nano', 't2.2xlarge', 'm4.large', 'm4.16xlarge', 
                                               'm3.medium', 'm3.2xlarge', 'c4.large', 'c4.8xlarge', 
                                               'c3.large', 'c3.8xlarge', 'p2.xlarge', 'p2.16xlarge', 
                                               'g2.2xlarge', 'g2.8xlarge', 'x1.16xlarge', 'x1.32xlarge', 
                                               'r4.large', 'r4.16xlarge', 'r3.large', 'r3.8xlarge', 'i3.large', 
                                               'i3.16xlarge', 'd2.xlarge', 'd2.8xlarge', 'f1.2xlarge', 'f1.16xlarge')
        default_tscfg['ATTACHED_VOLUME_ID']='vol-0761689f30f86656f' 
        default_tscfg['LOG_SAVE_PATH']='/home/cheshi/workspace/rhel74beta-disk-fio-test/'
    
        os.mknod(TSCFG_JSON_FILE)
        with open(TSCFG_JSON_FILE, 'w') as json_file:
            json_file.write(json.dumps(default_tscfg))
 
    with open(TSCFG_JSON_FILE, 'r') as json_file:
        my_dict = json.load(json_file)
        tscfg = byteify(my_dict)
        
    return tscfg


def run_case(instance_name, logfile, vmsize, disktype, rw, bs, iodepth, tformat, postfix):
    
    cmd_line = 'logfile="{0}"; '.format(logfile)
    cmd_line += 'vmsize="{0}"; disktype="{1}"; rw="{2}"; bs="{3}"; iodepth="{4}"; tformat="{5}"; postfix="{6}"'.format(
        vmsize, disktype, rw, bs, iodepth, tformat, postfix)
    
    cmd_line += '''
        PATH=$PATH:/usr/sbin/:/usr/local/bin/

        # Prepare the workspace
        if [ -z "$workspace" ]; then
            workspace="/tmp/fio-test/"
        fi
        mkdir -p $workspace && cd $workspace || exit 1
    
        # Prepare the command line
        if [ -z "$logfile" ]; then
            logfile="fio-$vmsize-$disktype-$rw-$bs-$iodepth-$format-$postfix.log"
        fi
    
        if [ "$(lsblk | grep disk | cut -d ' ' -f 1 | grep xv | grep -v da | wc -l)" != "1" ]; then
            echo "No or more than one additional volume found. Can not process."
            exit 1
        fi
    
        filename="/dev/$(lsblk | grep disk | cut -d ' ' -f 1 | grep xv | grep -v da)"
        
        cmd="sudo /usr/local/bin/fio --rw=$rw --size=10G --bs=$bs --iodepth=$iodepth --ioscheduler=deadline --direct=1 \
            --filename=$filename -ioengine=libaio --thread --group_reporting --numjobs=16 \
            --name=test --runtime=1m --time_based"
        
        # Run the test
        echo -e "\nLog Name: \n----------\n" > $logfile
        echo $logfile >> $logfile
        
        echo -e "\nBase Check: \n----------\n" >> $logfile
        cat /etc/system-release >> $logfile
        echo >> $logfile
        uname -a >> $logfile
        echo >> $logfile
        lsblk -t >> $logfile
        
        echo -e "\nTest Command: \n----------\n" >> $logfile
        echo $cmd >> $logfile
        
        echo -e "\nCommand Outputs: \n----------\n" >> $logfile
        $cmd >> $logfile 2>&1
    
        # Get the bandwidth and IOPS, then write down a summary
        #BW=`grep iops $logfile | awk -F', ' '{ split($2, parts1, "=") } { split(parts1[2], parts2, "K") } { print parts2[1] }'`
        #IOPS=`grep iops $logfile | awk -F', ' '{ split($3, parts3, "=") } { print parts3[2]}'`
        BW=`grep IOPS $logfile | cut -d= -f3 | cut -d" " -f1`
        IOPS=`grep IOPS $logfile | cut -d= -f2 | cut -d, -f1`
        
        echo -e "\nTest Summary: \n----------\n" >> $logfile
        printf "%-12s %-10s %-10s %-6s %-9s %-9s %-12s %-8s\n" VMSize DiskType I/OMode BS IODepth Format BandWidth IOPS >> $logfile
        printf "%-12s %-10s %-10s %-6s %-9s %-9s %-12s %-8s\n" $vmsize $disktype $rw $bs $iodepth $tformat $BW $IOPS >> $logfile
    
        #cat $logfile
        exit 0
    '''

    result = run_shell_command_on_instance(region=TSCFG['REGION'], instance_name=instance_name, cmd_line=cmd_line)
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    return True
    

def run_test_suite(instance_name, vmsize):

    # preparation
    os.system('mkdir -p ' + TSCFG['LOG_SAVE_PATH'])

    # run test suite on client

    # Reference:
    # RW="read write randread randwrite"
    # BS="4k 16k 64k 256k"
    # IODEPTH="1 8 64"
    # SIZE="10G"

    disktype = 'gp2.10g'
    tformat = 'raw'
    postfix = '1'
    rw_list=('read', 'write', 'randread', 'randwrite')
    bs_list=('4k', '256k')
    iodepth_list=('1',)
   
    for rw in rw_list:
        for bs in bs_list:
            for iodepth in iodepth_list:
                # specify the log file
                logfile = 'fio-{0}-{1}-{2}-{3}-{4}-{5}-{6}.log'.format(
                    vmsize, disktype, rw, bs, iodepth, tformat, postfix)
                
                # run this test
                print 'Run case on instance...'
                run_case(instance_name, logfile, vmsize, disktype, rw, bs, iodepth, tformat, postfix)
                
                # get the log file
                print 'Getting log file {0}...'.format(logfile)
                get_file_from_instance(region=TSCFG['REGION'],
                                       instance_name = instance_name,
                                       src = '/tmp/fio-test/' + logfile,
                                       dst = TSCFG['LOG_SAVE_PATH'] + logfile)

    return True


def test(instance_type):
    '''test suite 02: check disk performance with fio.'''
    
    instance_name = 'cheshi-tc02-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name, instance_type=instance_type, 
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        
        attach_volume_to_instance(region=TSCFG['REGION'], instance_name=instance_name, 
                                  volume_id=TSCFG['ATTACHED_VOLUME_ID'], volume_delete_on_termination=False)

        print 'Waiting 2 minutes...'
        time.sleep(120)

        print 'Start to run test suite on {0}...'.format(instance_type)
        run_test_suite(instance_name, instance_type)
        print 'Instance type "{0}" finished.'.format(instance_type)
 
    except Exception, e:
        print 'Failed!'
        print '----------\n', e, '\n----------'
    
    finally:
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name, quick=False)

    return True


# Load test suite Configuration
TSCFG = load_tscfg()

if __name__ == '__main__':
    
    print 'TSCFG = ', TSCFG
    
    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:
        pass#test(instance_type)
        
    print 'Job finished!'


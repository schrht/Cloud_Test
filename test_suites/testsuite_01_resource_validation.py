#!/usr/bin/env python
# -*- coding:utf-8 -*-

import sys
import time
import random
import os
import json

sys.path.append('..')
from cloud.ec2cli import create_instance
from cloud.ec2cli import run_shell_command_on_instance
from cloud.ec2cli import terminate_instance
from cloud.ec2cli import get_file_from_instance


def load_tscfg():
    '''load test suite configuration'''
    
    TSCFG_JSON_FILE = './testsuite_01_configuration.json'
    
    def byteify(input):
        '''Convert unicode to string for JSON.loads'''
        if isinstance(input, dict):
            return {byteify(key):byteify(value) for key, value in input.iteritems()}
        elif isinstance(input, list):
            return [byteify(element) for element in input]
        elif isinstance(input, unicode):
            return input.encode('utf-8')
        else:
            return input

    
    if not os.path.exists(TSCFG_JSON_FILE):
        default_tscfg = {}
        default_tscfg['REGION'] = 'us-east-1'
        default_tscfg['IMAGE_ID'] = 'ami-5bc4964d'
        default_tscfg['SUBNET_ID'] = 'subnet-73f7162b'
        default_tscfg['SECURITY_GROUP_IDS'] = ('sg-aef4fad0',)
        default_tscfg['INSTANCE_TYPE_LIST'] = ('t2.nano', 't2.micro', 't2.2xlarge', 'm4.large', 'm4.10xlarge',
                                               'm4.16xlarge', 'm3.medium', 'm3.2xlarge', 'c4.large', 'c4.xlarge',
                                               'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'c3.large', 'c3.xlarge',
                                               'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'p2.xlarge', 'p2.8xlarge',
                                               'p2.16xlarge', 'g2.2xlarge', 'g2.8xlarge', 'x1.16xlarge', 'x1.32xlarge',
                                               'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge',
                                               'r4.16xlarge', 'r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge',
                                               'r3.8xlarge', 'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge',
                                               'i3.8xlarge', 'i3.16xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge',
                                               'd2.8xlarge', 'f1.2xlarge', 'f1.16xlarge')
        default_tscfg['LOG_SAVE_PATH'] = '/home/cheshi/workspace/rhel74beta-resource-check/'
    
        os.mknod(TSCFG_JSON_FILE)
        with open(TSCFG_JSON_FILE, 'w') as json_file:
            json_file.write(json.dumps(default_tscfg))
 
    with open(TSCFG_JSON_FILE, 'r') as json_file:
        my_dict = json.load(json_file)
        tscfg = byteify(my_dict)
        
    return tscfg


def run_test_suite(instance_name, vmsize):

    # preparation
    os.system('mkdir -p ' + TSCFG['LOG_SAVE_PATH'])

    # run test suite on client
    postfix = 1

    # specify the log file
    logfile = 'resource-check-{0}-{1}.log'.format(vmsize, postfix)
                
    # prepare the command line
    cmd_line = 'logfile="{0}"; vmsize="{1}"; postfix="{2}"'.format(logfile, vmsize, postfix)
    
    cmd_line += '''
        PATH=$PATH:/usr/sbin/:/usr/local/bin/

        # Prepare the workspace
        if [ -z "$workspace" ]; then
            workspace="/tmp/resource-check/"
        fi
        mkdir -p $workspace && cd $workspace || exit 1
    
        # Prepare the command line
        if [ -z "$logfile" ]; then
            logfile="resource-check-$vmsize-$postfix.log"
        fi

        cmd="free; echo; lscpu"
        
        # Run the test
        echo -e "\nLog Name: \n----------\n" > $logfile
        echo $logfile >> $logfile
        
        echo -e "\nBase Check: \n----------\n" >> $logfile
        cat /etc/system-release >> $logfile
        echo >> $logfile
        uname -a >> $logfile
        
        echo -e "\nTest Command: \n----------\n" >> $logfile
        echo $cmd >> $logfile
        
        echo -e "\nCommand Outputs: \n----------\n" >> $logfile
        eval $cmd >> $logfile 2>&1
    
        # Get the total memory and CPU count, then write down a summary
        MEM=`grep "^Mem:" $logfile | awk '{print $2}'`
        CPU=`grep "^CPU(s):" $logfile | awk '{print $2}'`
        
        echo -e "\nTest Summary: \n----------\n" >> $logfile
        printf "%-12s %-6s %-12s\n" VMSize CPU# "MemSize(KB)" >> $logfile
        printf "%-12s %-6s %-12s\n" $vmsize $CPU $MEM >> $logfile
    
        #cat $logfile
        exit 0
    '''

    print 'Run case on instance...'
    result = run_shell_command_on_instance(region=TSCFG['REGION'], instance_name=instance_name, cmd_line=cmd_line)
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    
    # get the log file
    print 'Getting log file {0}...'.format(logfile)
    get_file_from_instance(region=TSCFG['REGION'],
                            instance_name=instance_name,
                            src='/tmp/resource-check/' + logfile,
                            dst=TSCFG['LOG_SAVE_PATH'] + logfile)

    return True


def test(instance_type):
    '''test suite 01: resource validation'''
    
    instance_name = 'cheshi-ts01-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name, instance_type=instance_type,
                        image_id=TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        
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

    

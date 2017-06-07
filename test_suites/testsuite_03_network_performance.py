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
from cloud.ec2cli import get_instance_info_by_name
from cloud.ec2cli import get_file_from_instance


def load_tscfg():
    '''load test suite configuration'''
    
    TSCFG_JSON_FILE = './testsuite_03_configuration.json'
    
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
        default_tscfg['LOG_SAVE_PATH']='/home/cheshi/workspace/rhel74beta-network-iperf-test/'
    
        os.mknod(TSCFG_JSON_FILE)
        with open(TSCFG_JSON_FILE, 'w') as json_file:
            json_file.write(json.dumps(default_tscfg))
 
    with open(TSCFG_JSON_FILE, 'r') as json_file:
        my_dict = json.load(json_file)
        tscfg = byteify(my_dict)
        
    return tscfg


def run_test(instance_name, logfile, vmsize, iface, svrip, len, pc, postfix):

    cmd_line = 'logfile="{0}"; vmsize="{1}"; iface="{2}"; server_ip="{3}"; len="{4}"; pc="{5}"; postfix="{6}";'.format(
        logfile, vmsize, iface, svrip, len, pc, postfix)
        
    cmd_line += '''
        PATH=$PATH:/usr/sbin/:/usr/local/bin/
        
        # Prepare the workspace
        if [ -z "$workspace" ]; then
            workspace="/tmp/iperf-test/"
        fi
        mkdir -p $workspace && cd $workspace || exit 1

        # enlarge MTU
        sudo ifconfig $iface mtu 9000
    
        # Prepare the command line
        if [ -z "$logfile" ]; then
            logfile="iperf-$vmsize-$iface-$len-$pc-$postfix.log"
        fi
    
        cmd="sudo /usr/bin/iperf3 -c $server_ip -l $len -P $pc -f m"
        
        # Run the test
        echo -e "\nLog Name: \n----------\n" > $logfile
        echo $logfile >> $logfile
        
        echo -e "\nBase Check: \n----------\n" >> $logfile
        cat /etc/system-release >> $logfile
        echo >> $logfile
        uname -a >> $logfile
        echo >> $logfile
        ifconfig -a >> $logfile
        
        echo -e "\nTest Command: \n----------\n" >> $logfile
        echo $cmd >> $logfile
        
        echo -e "\nCommand Outputs: \n----------\n" >> $logfile
        $cmd >> $logfile 2>&1
    
        # Get the bandwidth and IOPS, then write down a summary
        BWtx=`grep "sender" $logfile | tail -1 | cut -d] -f2 | awk '{print $5}'`
        BWrx=`grep "receiver" $logfile | tail -1 | cut -d] -f2 | awk '{print $5}'`
        
        echo -e "\nTest Summary: \n----------\n" >> $logfile
        printf "%-12s %-10s %-6s %-7s %-10s %-10s\n" VMSize Interface Buffer PClient "BWtx(Mb/s)" "BWrx(Mb/s)" >> $logfile
        printf "%-12s %-10s %-6s %-7s %-10s %-10s\n" $vmsize $iface $len $pc $BWtx $BWrx >> $logfile

        #cat $logfile
        exit 0
    '''
    
    result = run_shell_command_on_instance(region=TSCFG['REGION'], instance_name=instance_name, cmd_line=cmd_line)
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    return True


def run_test_suite(instance_name, vmsize):

    # preparation
    os.system('mkdir -p ' + TSCFG['LOG_SAVE_PATH'])
    
    # start server
    cmd_line = '''
        PATH=$PATH:/usr/sbin/:/usr/local/bin/
        
        # set MTU
        sudo ifconfig eth0 mtu 9000
        
        # start iperf server
        iperf3 -s -D &
    '''
    
    print 'Start iperf3 server on: {0}...'.format(instance_name+'-s')
    run_shell_command_on_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', cmd_line=cmd_line)


    # run test suite on client
    
    print 'Start iperf3 client on: {0}...'.format(instance_name+'-c')

    my_server = get_instance_info_by_name(region=TSCFG['REGION'], instance_name=instance_name+'-s')
    svrip = my_server['private_ip_address'] 

    iface = 'eth0'
    postfix = '1'
    bl_list = ('1m', '128k')    # buffer length
    pc_list = ('4', '1')        # parallel client number
    
    for pc in pc_list:
        for bl in bl_list:
                # specify the log file
                logfile = 'iperf-{0}-{1}-{2}-{3}-{4}.log'.format(
                    vmsize, iface, bl, pc, postfix)
                
                # run this test
                print 'Run case on instance...'
                run_test(instance_name+'-c', logfile, vmsize, iface, svrip, bl, pc, postfix)
                
                # get the log file
                print 'Getting log file {0}...'.format(logfile)
                get_file_from_instance(region=TSCFG['REGION'],
                                       instance_name = instance_name+'-c',
                                       src = '/tmp/iperf-test/' + logfile,
                                       dst = TSCFG['LOG_SAVE_PATH'] + logfile)

    return True

    
def test(instance_type):
    '''test suite 03: check network performance with iperf.'''
    
    instance_name = 'cheshi-ts03-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', instance_type=instance_type, 
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-c', instance_type=instance_type, 
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        
        print 'Waiting 2 minutes...'
        time.sleep(120)

        print 'Start to run test suite on {0}...'.format(instance_type)
        run_test_suite(instance_name, instance_type)
        print 'Instance type "{0}" finished.'.format(instance_type)
 
    except Exception, e:
        print 'Failed!'
        print '----------\n', e, '\n----------'
    
    finally:
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', quick=False)
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name+'-c', quick=False)

    return True


# Load test suite Configuration
TSCFG = load_tscfg()

if __name__ == '__main__':
    
    print 'TSCFG = ', TSCFG
    
    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:
        pass#test(instance_type)
        
    print 'Job finished!'



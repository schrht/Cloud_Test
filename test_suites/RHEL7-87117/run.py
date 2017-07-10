#!/usr/bin/env python
# -*- coding:utf-8 -*-

import sys
import time
import random
import os
import json

sys.path.append('../../')
from cloud.ec2cli import create_instance, get_instance_info_by_name
from cloud.ec2cli import run_shell_command_on_instance
from cloud.ec2cli import terminate_instance
from cloud.ec2cli import upload_to_instance
from cloud.ec2cli import download_from_instance


def load_tscfg():
    '''load test suite configuration'''
    
    TSCFG_JSON_FILE = './configure.json'
    
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
        default_tscfg['CASE_ID'] = ''
        default_tscfg['IMAGE_ID'] = ''
        default_tscfg['SUBNET_ID'] = ''
        default_tscfg['SECURITY_GROUP_IDS'] = ('',)
        default_tscfg['INSTANCE_TYPE_LIST'] = ('t2.micro',)
        default_tscfg['LOG_SAVE_PATH'] = ''
    
        os.mknod(TSCFG_JSON_FILE)
        with open(TSCFG_JSON_FILE, 'w') as json_file:
            json_file.write(json.dumps(default_tscfg))
 
    with open(TSCFG_JSON_FILE, 'r') as json_file:
        my_dict = json.load(json_file)
        tscfg = byteify(my_dict)
        
    return tscfg


def prepare_on_instance(instance_name):
    
    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  cmd_line='mkdir -p ~/workspace/bin/')
    
    upload_to_instance(region=TSCFG['REGION'],
                        instance_name=instance_name,
                        src='../global_bin/*',
                        dst='~/workspace/bin/')
    
    upload_to_instance(region=TSCFG['REGION'],
                        instance_name=instance_name,
                        src='./bin/*',
                        dst='~/workspace/bin/')
    
    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  cmd_line='chmod 755 ~/workspace/bin/*')

    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  cmd_line='mkdir -p ~/workspace/log/ && rm -rf ~/workspace/log/*')
    
    return 


def collect_log_from_instance(instance_name):
    
    log_save_path = TSCFG['LOG_SAVE_PATH']
    
    os.system('mkdir -p ' + log_save_path)
    
    download_from_instance(region=TSCFG['REGION'],
                           instance_name=instance_name,
                           src='~/workspace/log/*',
                           dst=log_save_path)

    return


def run_test(instance_name, instance_type=None):

    # prepare
    print 'Preparing environment...'
    prepare_on_instance(instance_name+'-s')
    prepare_on_instance(instance_name+'-c')
    
    # run test
    print 'Running test on instance...'
    
    ## step 1: basic information
    result = run_shell_command_on_instance(region=TSCFG['REGION'], 
                                           instance_name=instance_name+'-c', 
                                           cmd_line='/bin/bash ~/workspace/bin/test.sh')
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    inst_id = get_instance_info_by_name(region=TSCFG['REGION'], instance_name=instance_name+'-c')['id']
    log_file = TSCFG['LOG_SAVE_PATH'] + 'aws_check_' + instance_type + '.log'
    os.system('aws ec2 describe-instances --instance-id {0} > {1}'.format(inst_id, log_file))
    os.system('aws ec2 describe-instances --instance-id {0} --query \'Reservations[].Instances[].EnaSupport\' >> {1}'.format(inst_id, log_file))
    
    ## step 2: iperf test
    result = run_shell_command_on_instance(region=TSCFG['REGION'], 
                                           instance_name=instance_name+'-s', 
                                           cmd_line='/bin/bash ~/workspace/bin/iperf_server.sh')
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    server_ip = get_instance_info_by_name(region=TSCFG['REGION'], instance_name=instance_name+'-s')['private_ip_address']
    
    result = run_shell_command_on_instance(region=TSCFG['REGION'], 
                                           instance_name=instance_name+'-c', 
                                           cmd_line='/bin/bash ~/workspace/bin/iperf_client.sh {0}'.format(server_ip))
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
    
    # get log
    print 'Getting log files...'
    collect_log_from_instance(instance_name+'-c')
    
    return


def test(instance_type):
    '''test on specific instance type'''
    
    instance_name = TSCFG['CASE_ID'].lower() + '-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', instance_type=instance_type, 
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-c', instance_type=instance_type, 
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        
        print 'Waiting 2 minutes...'
        time.sleep(120)

        print 'Start to run test on {0}...'.format(instance_type)
        run_test(instance_name, instance_type)
        print 'Test on instance type "{0}" finished.'.format(instance_type)
 
    except Exception, e:
        print 'Failed!'
        print '----------\n', e, '\n----------'
    
    finally:
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', quick=False)
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name+'-c', quick=False)

    return


# Load test suite Configuration
TSCFG = load_tscfg()

if __name__ == '__main__':
    
    print 'TSCFG = ', TSCFG

    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:
        test(instance_type)
    
    #run_test('cheshi-script-test', 't2.micro')
        
    print 'Job finished!'

    

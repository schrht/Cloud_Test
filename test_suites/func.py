#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
import json
import time
import sys

sys.path.append('../')
from cloud.ec2cli import run_instant_command_on_instance
from cloud.ec2cli import run_shell_command_on_instance
from cloud.ec2cli import upload_to_instance
from cloud.ec2cli import download_from_instance


def byteify(inputs):
    '''Convert unicode to string for JSON.loads'''
    if isinstance(inputs, dict):
        return {byteify(key):byteify(value) for key, value in inputs.iteritems()}
    elif isinstance(inputs, list):
        return [byteify(element) for element in inputs]
    elif isinstance(inputs, unicode):
        return inputs.encode('utf-8')
    else:
        return inputs


def load_tscfg(data_file = './configure.json'):
    '''load test suite configuration'''

    # data
    tscfg = {}

    if not os.path.exists(data_file):
        # create the data file
        tscfg['CASE_ID'] = 'rhelx-00000'
        os.mknod(data_file)
        with open(data_file, 'w') as f:
            f.write(json.dumps(tscfg))
    else:
        # read from data file
        with open(data_file, 'r') as f:
            tscfg = byteify(json.load(f))
        
    # data validation
    if not tscfg.has_key('CASE_ID'):
        tscfg['CASE_ID'] = 'rhelx-00000'

    if not tscfg.has_key('LOG_SAVE_PATH'):
        tscfg['LOG_SAVE_PATH'] = '/tmp/'
        
    if not tscfg.has_key('REGION'):
        tscfg['REGION'] = None
        
    if not tscfg.has_key('USER_NAME'):
        tscfg['USER_NAME'] = None
        
    if not tscfg.has_key('IMAGE_ID'):
        tscfg['IMAGE_ID'] = None
        
    if not tscfg.has_key('SUBNET_ID'):
        tscfg['SUBNET_ID'] = None
        
    if not tscfg.has_key('SECURITY_GROUP_IDS'):
        tscfg['SECURITY_GROUP_IDS'] = None
        
    if not tscfg.has_key('INSTANCE_TYPE_LIST'):
        tscfg['INSTANCE_TYPE_LIST'] = ('t2.micro',)
        
        
    return tscfg


def waiting_for_instance_online(region, instance_name, user_name = 'ec2-user', time_out = 600):
    '''Waiting for the instance to be able to connect with via ssh.
    Retrun Value: SSH connectivity
    '''
    
    result_code = 1
    start_time = time.time()

    print 'Waiting for Instance...'
    
    while result_code != 0 and (time.time() - start_time) < time_out:
        # tring to connect instance
        time.sleep(10)
        result_code = run_instant_command_on_instance(region = region, instance_name = instance_name,
                                                 user_name = user_name, timeout = 2, command = 'echo >/dev/null')

    if result_code == 0:
        # command succeed via ssh connection
        print 'Waited {0}s for the instance can be connected by ssh.'.format(time.time() - start_time)
        
        return True
    else:
        print 'Waited {0}s but the instance still can\'t be reached by ssh.'.format(time.time() - start_time)

        return False


def prepare_on_instance(tscfg, instance_name):
    '''Prepare environment for the test to run.
    Jobs:
        1. mkdir workspace/bin workspace/log
        2. upload test scripts to workspace/bin and chmod 755
        3. clean logs under workspace/log
    Inputs:
        tscfg         : dict, test suite configuration
        instance_name : string, the name of instance
    Retrun Value:
        Always None
    '''
    
    run_shell_command_on_instance(region=tscfg['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=tscfg['USER_NAME'], 
                                  cmd_line='mkdir -p ~/workspace/bin/')
    
    upload_to_instance(region=tscfg['REGION'],
                        instance_name=instance_name,
                        user_name=tscfg['USER_NAME'], 
                        src='../global_bin/*',
                        dst='~/workspace/bin/')
    
    upload_to_instance(region=tscfg['REGION'],
                        instance_name=instance_name,
                        user_name=tscfg['USER_NAME'], 
                        src='./bin/*',
                        dst='~/workspace/bin/')
    
    run_shell_command_on_instance(region=tscfg['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=tscfg['USER_NAME'], 
                                  cmd_line='chmod 755 ~/workspace/bin/*')

    run_shell_command_on_instance(region=tscfg['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=tscfg['USER_NAME'], 
                                  cmd_line='mkdir -p ~/workspace/log/ && rm -rf ~/workspace/log/*')
    
    return 


def collect_log_from_instance(tscfg, instance_name):
    '''Collect log fils from instance.
    Jobs:
        1. mkdir to save log files on local host
        2. download all log files from worksapce/log
    Inputs:
        tscfg         : dict, test suite configuration
        instance_name : string, the name of instance
    Retrun Value:
        Always None
    '''
    
    log_save_path = tscfg['LOG_SAVE_PATH']
    
    os.system('mkdir -p ' + log_save_path)
    
    download_from_instance(region=tscfg['REGION'],
                           instance_name=instance_name,
                           user_name=tscfg['USER_NAME'], 
                           src='~/workspace/log/*',
                           dst=log_save_path)

    return



if __name__ == '__main__':
    
    pass

    #waiting_for_instance_online('ap-northeast-1', 'cheshi-script-test', user_name = 'ec2-user', time_out=60)
    
    
    
    
    

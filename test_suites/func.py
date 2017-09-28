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
from cloud.ec2cli import get_instance_state


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


def load_tscfg(data_file = './configure.json', default_data_file='../default_configure.json'):
    '''Load test suite configuration
    Strategy:
        1. Load config data from specified data_file;
        2. Load default config data from test_suites/default_configure.json;
    Reture Value:
        tscfg : dict, test suite configuration
    '''

    # test suite configuration
    tscfg = {}

    # if specified data_file exists, load config data
    if os.path.exists(data_file):
        with open(data_file, 'r') as f:
            tscfg = byteify(json.load(f))


    # load default config data
    default_tscfg={}

    if not os.path.exists(default_data_file):
        # default_configure.json must exist, create one if not
        default_tscfg['CASE_ID'] = 'RHEL7-00000'
        default_tscfg['LOG_SAVE_PATH'] = '/home/cheshi/workspace/rhel74-test-outputs/'
        default_tscfg['REGION'] = 'ap-northeast-1'
        default_tscfg['USER_NAME'] = 'ec2-user'
        default_tscfg['IMAGE_ID'] = 'ami-3901e15f'
        default_tscfg['SUBNET_ID'] = 'subnet-989a6bef'
        default_tscfg['SECURITY_GROUP_IDS'] = ('sg-010ffc67',)
        default_tscfg['INSTANCE_TYPE_LIST'] = ('t2.nano',)

        os.mknod(default_data_file)
        with open(default_data_file, 'w') as f:
            f.write(json.dumps(default_tscfg))

    # load default config data from default_configure.json
    with open(default_data_file, 'r') as f:
        default_tscfg = byteify(json.load(f))


    # data validation and set default value
    for key in default_tscfg:
        if not tscfg.has_key(key):
            tscfg[key] = default_tscfg[key]

    return tscfg


def waiting_for_instance_online(region, instance_name, user_name = 'ec2-user', time_out = 600):
    '''Waiting for the instance can be connected by ssh.
    Retrun Value:
        bool, represents the SSH connectivity
    '''

    state = get_instance_state(instance_name = instance_name)
    print 'Current instance state is {0}'.format(state)

    if state != 'running':
        print 'Target instance not in running state, exit now.'
        return False

    result_code = 1
    start_time = time.time()

    print 'Waiting for the instance (keep tring)...'

    while result_code != 0 and (time.time() - start_time) < time_out:
        # tring to connect instance
        time.sleep(10)
        result_code = run_instant_command_on_instance(region = region, instance_name = instance_name,
                                                 user_name = user_name, timeout = 2, command = 'echo >/dev/null')

    if result_code == 0:
        # ssh connection is OK now
        print 'Waited {0}s for the instance can be connected by ssh.'.format(time.time() - start_time)
        return True
    else:
        # time out
        print 'Waited {0}s but the instance still can\'t be connected by ssh.'.format(time.time() - start_time)
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

    log_save_path = tscfg['LOG_SAVE_PATH'] + tscfg['CASE_ID'] + '/'

    os.system('mkdir -p ' + log_save_path)

    download_from_instance(region=tscfg['REGION'],
                           instance_name=instance_name,
                           user_name=tscfg['USER_NAME'],
                           src='~/workspace/log/*',
                           dst=log_save_path)

    return


if __name__ == '__main__':

    pass

    #print '=============\n', load_tscfg(default_data_file='./default_configure.json')
    #waiting_for_instance_online('ap-northeast-1', 'cheshi-script-test', user_name = 'ec2-user', time_out=60)


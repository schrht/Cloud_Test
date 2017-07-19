#!/usr/bin/env python
# -*- coding:utf-8 -*-

import sys
import time
import random
import os

sys.path.append('../../')
from cloud.ec2cli import create_instance
from cloud.ec2cli import run_shell_command_on_instance
from cloud.ec2cli import terminate_instance
from cloud.ec2cli import upload_to_instance
from cloud.ec2cli import download_from_instance
from cloud.ec2cli import attach_volume_to_instance
from cloud.ec2cli import detach_volume_from_instance

from test_suites.func import load_tscfg


def prepare_on_instance(instance_name):
    
    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=TSCFG['USER_NAME'], 
                                  cmd_line='mkdir -p ~/workspace/bin/')
    
    upload_to_instance(region=TSCFG['REGION'],
                        instance_name=instance_name,
                        user_name=TSCFG['USER_NAME'], 
                        src='../global_bin/*',
                        dst='~/workspace/bin/')
    
    upload_to_instance(region=TSCFG['REGION'],
                        instance_name=instance_name,
                        user_name=TSCFG['USER_NAME'], 
                        src='./bin/*',
                        dst='~/workspace/bin/')
    
    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=TSCFG['USER_NAME'], 
                                  cmd_line='chmod 755 ~/workspace/bin/*')

    run_shell_command_on_instance(region=TSCFG['REGION'], 
                                  instance_name=instance_name, 
                                  user_name=TSCFG['USER_NAME'], 
                                  cmd_line='mkdir -p ~/workspace/log/ && rm -rf ~/workspace/log/*')
    
    return 


def collect_log_from_instance(instance_name):
    
    log_save_path = TSCFG['LOG_SAVE_PATH']
    
    os.system('mkdir -p ' + log_save_path)
    
    download_from_instance(region=TSCFG['REGION'],
                           instance_name=instance_name,
                           user_name=TSCFG['USER_NAME'], 
                           src='~/workspace/log/*',
                           dst=log_save_path)

    return


def run_test(instance_name, instance_type=None):

    # prepare
    print 'Preparing environment...'
    prepare_on_instance(instance_name)
    
    # run test
    for volume in TSCFG['ATTACHED_VOLUME_IDS']:
        volume_id = volume.split(';')[0]
        volume_type = volume.split(';')[1]
    
        print 'Attaching test volume...'
        attach_volume_to_instance(region=TSCFG['REGION'], instance_name=instance_name,
                                  volume_id=volume_id, volume_delete_on_termination=False)
                
        print 'Running test on instance...'        
        result = run_shell_command_on_instance(region=TSCFG['REGION'], 
                                               instance_name=instance_name, 
                                               user_name=TSCFG['USER_NAME'], 
                                               cmd_line='/bin/bash ~/workspace/bin/test.sh ' + volume_type)
        #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)
        
        print 'Detaching test volume...'
        detach_volume_from_instance(region=TSCFG['REGION'], instance_name=instance_name,
                                  volume_id=volume_id, force=True)
    
    # get log
    print 'Getting log files...'
    collect_log_from_instance(instance_name)
    
    return


def test(instance_type):
    '''test on specific instance type'''
    
    instance_name = TSCFG['CASE_ID'].lower() + '-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name, instance_type=instance_type,
                        image_id=TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        
        print 'Waiting 2 minutes...'
        time.sleep(120)

        print 'Start to run test on {0}...'.format(instance_type)
        run_test(instance_name, instance_type)
        print 'Test on instance type "{0}" finished.'.format(instance_type)
 
    except Exception, e:
        print 'Failed!'
        print '----------\n', e, '\n----------'
    
    finally:
        terminate_instance(region=TSCFG['REGION'], instance_name=instance_name, quick=False)

    return


# Load test suite Configuration
TSCFG = load_tscfg('./configure.json')

if __name__ == '__main__':
    
    print 'TSCFG = ', TSCFG

    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:
        test(instance_type)
    
    #run_test('cheshi-storage-test')
    
    print 'Job finished!'

    

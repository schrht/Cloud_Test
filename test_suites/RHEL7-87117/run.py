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

from test_suites.func import load_tscfg
from test_suites.func import prepare_on_instance
from test_suites.func import collect_log_from_instance
from test_suites.func import waiting_for_instance_online


def run_test(instance_name, instance_type=None):

    # prepare
    print 'Preparing environment...'
    prepare_on_instance(TSCFG, instance_name + '-s')
    prepare_on_instance(TSCFG, instance_name + '-c')

    # run test
    print 'Running test on instance...'

    ## step 1: basic information
    result = run_shell_command_on_instance(region=TSCFG['REGION'],
                                           instance_name=instance_name+'-c',
                                           cmd_line='/bin/bash ~/workspace/bin/test.sh')
    #print 'status:\n----------\n%s\nstdout:\n----------\n%s\nstderr:\n----------\n%s\n' % (result)

    inst_id = get_instance_info_by_name(region=TSCFG['REGION'], instance_name=instance_name+'-c')['id']
    log_save_path = TSCFG['LOG_SAVE_PATH'] + TSCFG['CASE_ID'] + '/'
    log_file = log_save_path + 'aws_check_' + instance_type + '.log'

    os.system('mkdir -p ' + log_save_path)
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
    collect_log_from_instance(TSCFG, instance_name + '-s')
    collect_log_from_instance(TSCFG, instance_name + '-c')

    return


def test(instance_type):
    '''test on specific instance type'''

    instance_name = TSCFG['CASE_ID'].lower() + '-' + instance_type + '-' + str(random.randint(10000000, 99999999))

    try:
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-s', instance_type=instance_type,
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])
        create_instance(region=TSCFG['REGION'], instance_name=instance_name+'-c', instance_type=instance_type,
                        image_id = TSCFG['IMAGE_ID'], subnet_id=TSCFG['SUBNET_ID'], security_group_ids=TSCFG['SECURITY_GROUP_IDS'])

        waiting_for_instance_online(region=TSCFG['REGION'], instance_name=instance_name+'-s', user_name=TSCFG['USER_NAME'])
        waiting_for_instance_online(region=TSCFG['REGION'], instance_name=instance_name+'-c', user_name=TSCFG['USER_NAME'])

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
TSCFG = load_tscfg('./configure.json')

if __name__ == '__main__':

    print 'TSCFG = ', TSCFG

    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:
        test(instance_type)

    #run_test('cheshi-script-test', 't2.micro')

    print 'Job finished!'



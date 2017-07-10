#!/usr/bin/env python
#-*- coding:utf-8 -*-

# Author:
# Last Modified:

import os
import sys
import time
import json

import boto.ec2
from boto.manage.cmdshell import sshclient_from_instance


def load_ec2cfg():
    '''load ec2 configuration'''
    
    EC2CFG_JSON_FILE = '/home/cheshi/.ec2cfg.json'
    
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

    
    if not os.path.exists(EC2CFG_JSON_FILE):
        default_ec2cfg = {}
        default_ec2cfg['DEFAULT_REGION']='ap-northeast-1'
        default_ec2cfg['AWS_ACCESS_KEY_ID'] = 'AAAAAAAAAAAAAAAAAAAA'
        default_ec2cfg['AWS_SECRET_ACCESS_KEY'] = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
        default_ec2cfg['SECONDARY_VOLUME_DEVICE'] = '/dev/xvdf'
        default_ec2cfg['PEM'] = {}
        default_ec2cfg['PEM']['ap-northeast-1'] = '/home/cheshi/.pem/ap-northeast-1-cheshi.pem'
        default_ec2cfg['PEM']['ap-us-east-1'] = '/home/cheshi/.pem/ap-us-east-1-cheshi.pem'
    
        os.mknod(EC2CFG_JSON_FILE)
        with open(EC2CFG_JSON_FILE, 'w') as json_file:
            json_file.write(json.dumps(default_ec2cfg))
 
    with open(EC2CFG_JSON_FILE, 'r') as json_file:
        my_dict = json.load(json_file)
        ec2cfg = byteify(my_dict)
        
    return ec2cfg


def get_connection(region = None):
    '''get connection to the region'''
    
    conn = None
    
    if region == None:
        region = EC2CFG['DEFAULT_REGION']
    
    if isinstance(region, str):
        conn = boto.ec2.connect_to_region(
            region,
            aws_access_key_id=EC2CFG['AWS_ACCESS_KEY_ID'],
            aws_secret_access_key=EC2CFG['AWS_SECRET_ACCESS_KEY'])
        
    if conn is None:
        sys.stderr.write("ERROR: Connect to region \"%s\" failed.\n" % (region))
        
    return conn


def create_instance(region = None, instance_name = 'cheshi-test1', 
                    image_id = 'ami-4806342f', instance_type = 't2.micro',
                    key_name = 'cheshi', security_group_ids = ['launch-wizard-41'],
                    subnet_id = None, private_ip_address = None,
                    volume_delete_on_termination = True):
    '''Create an EC2 instance.'''

    # connect to region    
    conn = get_connection(region)
    
    # check if instance already exists
    existing_reservations = conn.get_all_instances(
        filters={"tag:Name": "%s" % instance_name})
    for existing_reservation in existing_reservations:
        existing_instance = existing_reservation.instances[0]
        if existing_instance:
            print "instance_name: %s already exists" % (instance_name)
            return False

    # launch instance
    print "1. Launching instance: %s" % (instance_name)
    
    print(
        image_id,
        instance_type,
        key_name,
        security_group_ids,
        subnet_id,
        private_ip_address,
        "stop")

    reservation = conn.run_instances(
        image_id,
        instance_type=instance_type,
        key_name=key_name,
        security_group_ids=security_group_ids,
        subnet_id=subnet_id,
        private_ip_address=private_ip_address,
        instance_initiated_shutdown_behavior="stop")

    # get instance
    instance = reservation.instances[0]
    
    # set instance name
    print "2. Creating tag as instance name: {\"Name\": %s}" % (instance_name)
    conn.create_tags(instance.id, {"Name": instance_name})
    
    # waiting for running
    while instance.state == u'pending':
        time.sleep(10)
        instance.update()
        print "Instance state: %s" % (instance.state)

    # volume_delete_on_termination
    if volume_delete_on_termination:
        root_device = instance.root_device_name
        instance.modify_attribute('blockDeviceMapping', {root_device: True})

    return True


def terminate_instance(region = None, instance_name = None, instance_id = None, quick = False):
    '''Terminate an EC2 instance.'''
    
    # connect to region    
    conn = get_connection(region)
    
    # provide instance name
    if instance_name:
        reservations = conn.get_all_instances(
            filters={"tag:Name": "%s" % (instance_name)})
        
        for reservation in reservations:
            instance = reservation.instances[0]
            print "Terminating instance: %s id: %s" % (instance_name, instance.id)
            
            instance_id_list = instance.id.split()
            conn.terminate_instances(instance_ids=instance_id_list)
            
            if not quick:
                while instance.state != u'terminated':
                    time.sleep(10)
                    instance.update()
                    print "Instance state: %s" % (instance.state)

    # provide instance id
    if instance_id:
        print "Terminating instance by id: %s" % (instance_id)
        
        instance_id_list = instance_id.split()
        conn.terminate_instances(instance_ids=instance_id_list)
        
        reservations = conn.get_all_reservations(instance_id)
        reservation = reservations[0]
        instance = reservation.instances[0]
        if not quick:
            while instance.state != u'terminated':
                time.sleep(20)
                instance.update()
                print "Instance state: {0}".format(instance.state)

    return True


def get_instance_info_by_name(region = None, instance_name = None):
    '''Get instance dict from EC2 service by providing instance name.'''
    
    # connect to region    
    conn = get_connection(region)

    # get instance information by name
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % instance_name})[0]
    instance = reservation.instances[0]
    
    return instance.__dict__.copy()


def attach_volume_to_instance(region = None, instance_name = None, volume_id = None, volume_delete_on_termination = True):
    '''Attach volume to an existing EC2 instance.'''
    
    # connect to region    
    conn = get_connection(region)

    # get instance
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % instance_name})[0]
    instance = reservation.instances[0]
    
    volume_device = EC2CFG['SECONDARY_VOLUME_DEVICE']

    print "Attaching volume: %s to instance: %s as device: %s" % (volume_id, instance.id, volume_device)
    conn.attach_volume(volume_id, instance.id, volume_device)
    if volume_delete_on_termination:
        instance.modify_attribute('blockDeviceMapping', {volume_device: True})
    
    
def run_shell_command_on_instance(region = None, instance_name = None, cmd_line = None):
    '''Run shell command on EC2 instance.'''

    if region == None:
        region = EC2CFG['DEFAULT_REGION']
        
    # connect to region    
    conn = get_connection(region)

    # get the instance object related to instance name
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % (instance_name)})[0]
    instance = reservation.instances[0]

    # create an SSH client for this instance
    ssh_client = sshclient_from_instance(instance, EC2CFG['PEM'][region], user_name='ec2-user')
    
    # run the command and get the results
    status, stdout, stderr = ssh_client.run(cmd_line)

    return (status, stdout, stderr)


def get_file_from_instance(region = None, instance_name = None, src = None, dst = True):
    '''Download file from EC2 instance.'''

    if region == None:
        region = EC2CFG['DEFAULT_REGION']

    # connect to region
    conn = get_connection(region)

    # get the instance object related to instance name
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % (instance_name)})[0]
    instance = reservation.instances[0]

    # create an SSH client for this instance
    ssh_client = sshclient_from_instance(instance, EC2CFG['PEM'][region], user_name='ec2-user')
    
    # get file from instance
    ssh_client.get_file(src, dst)

    return None


def download_from_instance(region = None, instance_name = None, src = None, dst = None):
    '''Download files from EC2 instance, implemented by `scp`.'''

    if region == None:
        region = EC2CFG['DEFAULT_REGION']

    # get the instance object related to instance name
    public_dns_name = get_instance_info_by_name(region=region, instance_name=instance_name)['public_dns_name'] 
    
    # download the file
    #keyscan_cmd = 'ssh-keyscan ' + public_dns_name + ' >> ~/.ssh/known_hosts'
    #os.system(keyscan_cmd)
    download_cmd = 'scp -r -i ' + EC2CFG['PEM'][region] + ' ec2-user@' + public_dns_name + ':' + src + ' ' + dst
    os.system(download_cmd)

    return None


def upload_to_instance(region = None, instance_name = None, src = None, dst = None):
    '''Upload files to EC2 instance, implemented by `scp`.'''

    if region == None:
        region = EC2CFG['DEFAULT_REGION']

    # get the instance object related to instance name
    public_dns_name = get_instance_info_by_name(region=region, instance_name=instance_name)['public_dns_name'] 
    
    # download the file
    #keyscan_cmd = 'ssh-keyscan ' + public_dns_name + ' >> ~/.ssh/known_hosts'
    #os.system(keyscan_cmd)
    upload_cmd = 'scp -r -i ' + EC2CFG['PEM'][region] + ' ' + src + ' ec2-user@' + public_dns_name + ':' + dst
    os.system(upload_cmd)

    return None



# Load EC2 Configuration
EC2CFG = load_ec2cfg()

if __name__ == '__main__':

    #print EC2CFG
    
    pass

    #create_instance(region='us-east-1', instance_name='cheshi-test-2', instance_type='t2.micro', image_id = 'ami-1fb1e109', subnet_id='subnet-73f7162b', security_group_ids=['sg-aef4fad0'])
    #print run_shell_command_on_instance(region='us-east-1', instance_name = 'cheshi-test-2', cmd_line = 'uname -r')
    #terminate_instance(region='us-east-1', instance_name='cheshi-test-2')

    #download_from_instance(instance_name='cheshi-script-test', src='/home/ec2-user/*.txt', dst='/home/cheshi/temp')
    #upload_to_instance(instance_name='cheshi-script-test', src='/home/cheshi/temp/*g', dst='/home/ec2-user')

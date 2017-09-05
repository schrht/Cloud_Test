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

import boto3
from botocore.exceptions import ClientError


def load_ec2cfg():
    '''load ec2 configuration'''

    EC2CFG_JSON_FILE = '/home/cheshi/.ec2cfg.json'

    def byteify(inputs):
        '''Convert unicode to string for JSON.loads'''
        if isinstance(inputs, dict):
            return {byteify(key):byteify(value) for key,value in inputs.iteritems()}
        elif isinstance(inputs, list):
            return [byteify(element) for element in inputs]
        elif isinstance(inputs, unicode):
            return inputs.encode('utf-8')
        else:
            return inputs


    if not os.path.exists(EC2CFG_JSON_FILE):
        default_ec2cfg = {}
        default_ec2cfg['DEFAULT_REGION']='ap-northeast-1'
        default_ec2cfg['AWS_ACCESS_KEY_ID'] = 'AAAAAAAAAAAAAAAAAAAA'
        default_ec2cfg['AWS_SECRET_ACCESS_KEY'] = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
        default_ec2cfg['SECONDARY_VOLUME_DEVICE'] = '/dev/xvdf'
        default_ec2cfg['PEM'] = {}
        default_ec2cfg['PEM']['ap-northeast-1'] = '/home/cheshi/.pem/ap-northeast-1-cheshi.pem'
        default_ec2cfg['PEM']['ap-us-east-1'] = '/home/cheshi/.pem/ap-us-east-1-cheshi.pem'
        default_ec2cfg['DEFAULT_USER_NAME'] = 'ec2-user'

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

    if region is None or region == '':
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


def attach_volume_to_instance(region = None, instance_name = None, volume_id = None, volume_delete_on_termination = True, quick = False):
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

    if not quick:
        state = ''
        while state != u'attached':
            time.sleep(5)
            state = conn.get_all_volumes(volume_ids=volume_id)[0].attachment_state()
            print "Attachment state: %s" % (state)

    return


def detach_volume_from_instance(region = None, instance_name = None, volume_id = None, force = False, quick = False):
    '''Detach volume from an existing EC2 instance.'''

    # connect to region
    conn = get_connection(region)

    # get instance
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % instance_name})[0]
    instance = reservation.instances[0]

    volume_device = EC2CFG['SECONDARY_VOLUME_DEVICE']

    print "Detaching volume: %s from instance: %s as device: %s" % (volume_id, instance.id, volume_device)
    conn.detach_volume(volume_id, instance.id, volume_device, force)

    if not quick:
        state = ''
        while state != u'available':
            time.sleep(5)
            state = conn.get_all_volumes(volume_ids=volume_id)[0].volume_state()
            print "Volume state: %s" % (state)

    return


def run_shell_command_on_instance(region = None, instance_name = None, cmd_line = None, user_name = None):
    '''Run shell command on EC2 instance.'''

    if region is None or region == '':
        region = EC2CFG['DEFAULT_REGION']
    if user_name is None or region == '':
        user_name = EC2CFG['DEFAULT_USER_NAME']

    # connect to region
    conn = get_connection(region)

    # get the instance object related to instance name
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % (instance_name)})[0]
    instance = reservation.instances[0]

    # create an SSH client for this instance
    ssh_client = sshclient_from_instance(instance, EC2CFG['PEM'][region], user_name=user_name)

    # run the command and get the results
    status, stdout, stderr = ssh_client.run(cmd_line)

    return (status, stdout, stderr)


def get_file_from_instance(region = None, instance_name = None, src = None, dst = True, user_name = None):
    '''Download file from EC2 instance.'''

    if region is None or region == '':
        region = EC2CFG['DEFAULT_REGION']
    if user_name is None or region == '':
        user_name = EC2CFG['DEFAULT_USER_NAME']

    # connect to region
    conn = get_connection(region)

    # get the instance object related to instance name
    reservation = conn.get_all_instances(filters={"tag:Name": "%s" % (instance_name)})[0]
    instance = reservation.instances[0]

    # create an SSH client for this instance
    ssh_client = sshclient_from_instance(instance, EC2CFG['PEM'][region], user_name=user_name)

    # get file from instance
    ssh_client.get_file(src, dst)

    return None


def download_from_instance(region = None, instance_name = None, src = None, dst = None, user_name = None):
    '''Download files from EC2 instance, implemented by `scp`.'''

    if region is None or region == '':
        region = EC2CFG['DEFAULT_REGION']
    if user_name is None or region == '':
        user_name = EC2CFG['DEFAULT_USER_NAME']

    # get public_dns_name related to instance name
    public_dns_name = get_instance_info_by_name(region=region, instance_name=instance_name)['public_dns_name']

    # download the file
    cmd = 'ssh-keygen -q -R {0} >/dev/null 2>&1'.format(public_dns_name)
    os.system(cmd)

    cmd = 'scp -o StrictHostKeyChecking=no -r -i {0} {1}@{2}:{3} {4}'.format(EC2CFG['PEM'][region], user_name, public_dns_name, src, dst)
    os.system(cmd)

    return None


def upload_to_instance(region = None, instance_name = None, src = None, dst = None, user_name = None):
    '''Upload files to EC2 instance, implemented by `scp`.'''

    if region is None or region == '':
        region = EC2CFG['DEFAULT_REGION']
    if user_name is None or region == '':
        user_name = EC2CFG['DEFAULT_USER_NAME']

    # get public_dns_name related to instance name
    public_dns_name = get_instance_info_by_name(region=region, instance_name=instance_name)['public_dns_name']

    # upload the file
    cmd = 'ssh-keygen -q -R {0} >/dev/null 2>&1'.format(public_dns_name)
    os.system(cmd)

    cmd = 'scp -o StrictHostKeyChecking=no -r -i {0} {1} {2}@{3}:{4}'.format(EC2CFG['PEM'][region], src, user_name, public_dns_name, dst)
    os.system(cmd)

    return None


def run_instant_command_on_instance(region = None, instance_name = None, user_name = None, timeout = 0, command = 'uname -r'):
    '''Upload files to EC2 instance, implemented by `scp`.'''

    if region is None or region == '':
        region = EC2CFG['DEFAULT_REGION']
    if user_name is None or region == '':
        user_name = EC2CFG['DEFAULT_USER_NAME']

    if isinstance(timeout, int) and timeout > 0:
        cmd_timeout = '-o ConnectTimeout={0}'.format(timeout)
    else:
        cmd_timeout = ''

    # get public_dns_name related to instance name
    public_dns_name = get_instance_info_by_name(region=region, instance_name=instance_name)['public_dns_name']

    # check the connection
    cmd = 'ssh-keygen -q -R {0} >/dev/null 2>&1'.format(public_dns_name)
    os.system(cmd)

    cmd = 'ssh -o StrictHostKeyChecking=no {0} -i {1} {2}@{3} \'{4}\''.format(cmd_timeout, EC2CFG['PEM'][region], user_name, public_dns_name, command)
    status = os.system(cmd)

    return status


def create_volume(region = None, availability_zone = None, volume_type = None, volume_size = None, iops = None):

    # set default values
    if region is None or region == '': region = EC2CFG['DEFAULT_REGION']
    if availability_zone is None or region == '': availability_zone = region + 'a'

    # volume_size must be an integer
    if not isinstance(volume_size, int):
        try:
            converted_value = int(volume_size)
        except:
            print 'Error: volume_size must be an integer, and your provision "{0}" can not be converted. Return None.'.format(volume_size)
            return None
        else:
            print 'Warning: the volume_size you provisioned "{0}" has been converted as integer "{1}".'.format(volume_size, converted_value)
            volume_size = converted_value

    # connect to region
    conn = get_connection(region)

    # create volume and tags
    print 'Creating volume: Type="{0}", Size={1}GiB, IOPS={2} in availability zone "{3}"...'.format(volume_type, int(volume_size), iops, availability_zone)
    volume = conn.create_volume(size = int(volume_size), zone = availability_zone,
                                volume_type = volume_type, iops = iops)

    print 'Creating tag for volume {0}...'.format(volume.id)
    conn.create_tags(volume.id, {"Name": 'cheshi-volume-autotest'})

    print 'Wait 20 seconds for the volume become available...'
    time.sleep(20)

    return volume


def delete_volume(region = None, volume_id = None):

    # set default values
    if region is None or region == '': region = EC2CFG['DEFAULT_REGION']

    # connect to region
    conn = get_connection(region)

    # delete volume
    print 'Deleting volume: {0}...'.format(volume_id)
    result = conn.delete_volume(volume_id)

    return result


def create_placement_group(pg_name):
    '''Create a placement group.
    Parameters:
        pg_name: str, group name
    Reture values:
        None
    '''

    ec2 = boto3.client('ec2')

    try:
        ec2.create_placement_group(GroupName=pg_name, Strategy='cluster')
    except ClientError as e:
        if 'InvalidPlacementGroup.Duplicate' in str(e):
            print e
            return None
        else:
            print e
            raise

    return None


def delete_placement_group(pg_name):
    '''Delete a placement group.
    Parameters:
        pg_name: str, group name
    Reture values:
        None
    '''

    ec2 = boto3.client('ec2')

    try:
        ec2.delete_placement_group(GroupName=pg_name)
    except ClientError as e:
        if 'InvalidPlacementGroup.Unknown' in str(e):
            print e
        if 'InvalidPlacementGroup.InUse' in str(e):
            print e
        else:
            print e
            raise

    return None


def create_clustered_instances(region = None, pg_name = '', instance_names = [], image_id = '',
                               instance_type = '', key_name = 'cheshi', security_group_ids = [],
                               subnet_id = None, ipv6_address_count = 0, ebs_optimized = False):
    '''Create clustered EC2 instance.
    Parameters:
        pg_name        : str, the name of placement group for creating instances in.
        instance_names : list, the list of instnace name for creating instances.
        ......
    Reture values:
        None
    '''
    # check inputs
    if len(instance_names) < 2:
        print 'The length of instance_names must be 2 at least.'

    # connect to resource
    ec2 = boto3.resource('ec2')

    # check if instance already exists
    instance_iterator = ec2.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': instance_names}])
    instance_list = list(instance_iterator)

    if instance_list:
        for instance in instance_list:
            print '%s, known as %s, already exists.' % (instance, [x['Value'] for x in instance.tags if x['Key'] == 'Name'])
        print 'Exit without creating any instance.'
        return False

    # launch instance
    print '1. Creating instance: %s' % (instance_names)

    kwargs = {}
    kwargs['ImageId'] = image_id
    kwargs['InstanceType'] = instance_type
    kwargs['KeyName'] = key_name
    kwargs['SecurityGroupIds'] = security_group_ids
    kwargs['SubnetId'] = subnet_id
    kwargs['Ipv6AddressCount'] = ipv6_address_count
    kwargs['MinCount'] = kwargs['MaxCount'] = len(instance_names)
    kwargs['Placement'] = {'GroupName': pg_name}
    kwargs['EbsOptimized'] = ebs_optimized

    print 'kwargs = %s' % (kwargs)

    try:
        instance_list = ec2.create_instances(DryRun = True, **kwargs)
    except ClientError as e:
        if 'DryRunOperation' not in str(e):
            print e
            raise

    try:
        instance_list = ec2.create_instances(**kwargs)
        print(instance_list)
    except ClientError as e:
        print e
        raise

    # set instance name
    print '2. Creating tag as instance name'

    for (instance, instance_name) in zip(instance_list, instance_names):
        print '%s {\'Name\': %s}' % (instance, instance_name)
        ec2.create_tags(Resources = [instance.id], Tags = [{'Key': 'Name', 'Value': instance_name}])

    # waiting for running
    print '3. Waiting instance state become running'
    for instance in instance_list:
        instance.wait_until_running()

    print 'create_clustered_instances() finished'
    return True


def terminate_clustered_instances(region = None, instance_names = None, pg_name = None, quick = False):
    '''Terminate clustered EC2 instance.
    Parameters:
        pg_name        : str, group name (terminating all the instances in this group), or
        instance_names : list, instnace name list to be terminated.
        quick          : flag, without waiting for the instance state become terminated.
    Return values:
        None
    '''

    # check inputs
    if pg_name and instance_names:
        print 'pg_name and instance_names can not be specified at once.'
        return False
    elif not pg_name and not instance_names:
        print 'one of pg_name and instance_names should be specified.'
        return False

    # connect to resource
    ec2 = boto3.resource('ec2')

    # get instance list
    print '1. Collecting instance'
    if pg_name:
        instance_iterator = ec2.PlacementGroup(pg_name).instances.all()
    else:
        instance_iterator = ec2.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': instance_names}])

    instance_list = list(instance_iterator)
    print 'Instance list to be terminated: %s' % instance_list

    # terminate instance
    print '2. Terminating instance'
    for instance in instance_list:
        print 'Terminating %s...' % instance

        try:
            instance.terminate(DryRun=False)
        except ClientError as e:
            if 'DryRunOperation' not in str(e):
                print e
                raise

        try:
            instance.terminate()
        except ClientError as e:
            print e
            raise

    if not quick and instance_list:
        print '3. Waiting instance state become terminated'
        for instance in instance_list:
            instance.wait_until_terminated()

    print 'terminate_clustered_instances() finished'

    return None


def get_ipv6_addresses(region = None, instance_name = None):
    '''Get IPv6 addresses from specified instance.
    Parameters:
        region        : string, region id.
        instance_name : string, instnace name which specifies an instance.
    Return values:
        None : if the request can't be handled.
        List : the IPv6 address list associalated with the instance.
    Restrict:
        The instance_name must can identify an instance.
        The specified instance should have only one network interface, or the IPv6 address
        in the list can belong to any one of the interfaces.
    '''

    # connect to resource
    ec2 = boto3.resource('ec2')

    # get ipv6 address
    ipv6_list = []

    instance_list = list(ec2.instances.filter(Filters=[{'Name': 'tag:Name', 'Values': [instance_name]}]))
    if len(instance_list) != 1:
        print 'Found %s instance(s) by searching tag:Name %s, the request can not be handled.' % (len(instance_list), instance_name)
        return None
    else:
        instance = instance_list[0]

    for interface in instance.network_interfaces_attribute:
        for ipv6_address in interface['Ipv6Addresses']:
            ipv6_list.append(ipv6_address['Ipv6Address'])

    return ipv6_list


# Load EC2 Configuration
EC2CFG = load_ec2cfg()

if __name__ == '__main__':

    #print EC2CFG
    pass

    #create_clustered_instances(instance_names = ['cheshi-test-2'], image_id = 'ami-30ef0556',
    #                           instance_type = 't2.micro', key_name = 'cheshi', security_group_ids = ["sg-4381fa25"],
    #                           subnet_id = 'subnet-812033f7', ipv6_address_count = 2, ebs_optimized = False)

    #create_instance(region='us-east-1', instance_name='cheshi-test-2', instance_type='t2.micro', image_id = 'ami-1fb1e109', subnet_id='subnet-73f7162b', security_group_ids=['sg-aef4fad0'])
    #print run_shell_command_on_instance(region='us-east-1', instance_name = 'cheshi-test-2', cmd_line = 'uname -r')
    #terminate_instance(region='us-east-1', instance_name='cheshi-test-2')

    #download_from_instance(instance_name='cheshi-script-test', src='/home/ec2-user/*.txt', dst='/home/cheshi/temp')
    #upload_to_instance(instance_name='cheshi-script-test', src='/home/cheshi/temp/*g', dst='/home/ec2-user')

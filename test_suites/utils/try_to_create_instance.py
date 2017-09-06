#!/usr/bin/env python
# -*- coding:utf-8 -*-

import boto3
from botocore.exceptions import ClientError


TSCFG = {
    'REGION': 'ap-northeast-1',
    'USER_NAME': 'ec2-user',

    'IMAGE_ID': 'ami-30ef0556',
    'SUBNET_ID': 'subnet-812033f7',
    'SECURITY_GROUP_IDS': [
        'sg-4381fa25'
    ],
    'PLACEMENT': 'cheshi-pg',

    'INSTANCE_TYPE_LIST': [
        'i3.8xlarge',
        'i3.large',
        'i3.xlarge',
        'm3.2xlarge',
        'm3.large',
        'm3.medium',
        'm3.xlarge',
        'm4.10xlarge',
        'm4.16xlarge',
        'm4.2xlarge',
        'm4.4xlarge',
        'm4.large',
        'm4.xlarge',
        'p2.16xlarge',
        'p2.8xlarge',
        'p2.xlarge',
        'r3.2xlarge',
        'r3.4xlarge',
        'r3.8xlarge',
        'r3.large',
        'r3.xlarge',
        'r4.16xlarge',
        'r4.2xlarge',
        'r4.4xlarge',
        'r4.8xlarge',
        'r4.large',
        'r4.xlarge',
        't2.2xlarge',
        't2.large',
        't2.medium',
        't2.micro',
        't2.small',
        't2.xlarge',
        'x1.16xlarge',
        'x1.32xlarge',
    ]
}


def try_create_instances(region = TSCFG['REGION'], **kwargs):

    '''Create EC2 instance.
    Parameters:
        region         : string, the AWS region.
        instance_names : list, the list of instnace name for creating instances.
        pg_name        : string, the name of placement group for creating instances in.
        ......
    Reture values: dict
    '''

    # connect to resource
    ec2 = boto3.resource('ec2', region_name = region)

    # launch instance
    print 'Creating instance:'



    print 'kwargs = %s' % (kwargs)

    try:
        ec2.create_instances(DryRun = True, **kwargs)
    except ClientError as e:
        message = str(e)
        code = message[message.find('(') + 1 : message.find(')')]
        if 'DryRunOperation' not in message:
            print message
        return {'message': message, 'code': code}


if __name__ == '__main__':

    print 'TSCFG = ', TSCFG

    result_list = []

    min_max_count = 2
    ipv6_address_count = 0

    for instance_type in TSCFG['INSTANCE_TYPE_LIST']:

        kwargs = {}
        kwargs['ImageId'] = TSCFG['IMAGE_ID']
        kwargs['InstanceType'] = instance_type
        kwargs['KeyName'] = 'cheshi'
        kwargs['SecurityGroupIds'] = TSCFG['SECURITY_GROUP_IDS']
        kwargs['SubnetId'] = TSCFG['SUBNET_ID']
        kwargs['Ipv6AddressCount'] = ipv6_address_count
        kwargs['MinCount'] = min_max_count
        kwargs['MaxCount'] = min_max_count
        kwargs['Placement'] = {'GroupName': TSCFG['PLACEMENT']}
        kwargs['EbsOptimized'] = False

        response = try_create_instances(region = TSCFG['REGION'], **kwargs)

        result = {}
        result['InstanceType'] = instance_type
        result['Ipv6AddressCount'] = ipv6_address_count
        result['MinCount'] = min_max_count
        result['MaxCount'] = min_max_count
        result['Result_Code'] = response['code']
        result['Result_Message'] = response['message']

        result_list.append(result)

    print '\nResult\n===================='
    for item in result_list:
        print '{0}\t{1}\t'.format(item['InstanceType'], item['Result_Code'], item['Result_Message'])

    print 'Job finished!'



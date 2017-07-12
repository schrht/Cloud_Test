#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
import json


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



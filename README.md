# Cloud_Test

Cloud_Test is the simple test suites to perform my AWS test.

# Screenshot

N/A

# Setting up

## Donwload script

Download the source code from github:

```
git clone https://github.com/SCHEN2015/Cloud_Test.git
```

## Install library

ec2 script is built on top of boto and some other libraries then, first of all, install them using pip:

```
sudo pip install boto

#
# If 'pip' is not installed on your machine, try with:
# sudo easy_install pip
#

sudo pip install paramiko

#
# If 'paramiko' compile failed, try with:
# sudo yum install gcc libffi-devel python-devel openssl-devel
#

```

In most case it is enough but if you are running Mountain Lion you might need to export the variable as follow:

```
export PYTHONPATH=/usr/bin/python2.7
export PYTHONPATH=${PYTHONPATH}:$HOME/code/python/boto
change the python version according to your own.
```

# Edit the configuration file

Cloud_Test uses a property file in order to load default settings i.e. username, default pem file, default region, etc. Therefore, you must edit configuration file:

```
vi ~/.ec2cfg.json

# This file should be like this:

{
    "AWS_ACCESS_KEY_ID": "AAAAAAAAAAAAAAAAAAA",
    "AWS_SECRET_ACCESS_KEY": "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",

    "DEFAULT_REGION": "ap-northeast-1",

    "DEFAULT_USER_NAME": "ec2-user",
    "PEM": {
        "us-east-1": "/home/cheshi/.pem/us-east-1-cheshi.pem",
        "ap-northeast-1": "/home/cheshi/.pem/ap-northeast-1-cheshi.pem"
    },

    "SECONDARY_VOLUME_DEVICE": "/dev/xvdf"
}
```

# Usage

```
$ ls -d Cloud_Test/test_suites/RHEL*
RHEL7-87117  RHEL7-87122  RHEL7-87306  RHEL7-88713
RHEL7-87119  RHEL7-87124  RHEL7-87311  RHEL7-93100

$ cd Cloud_Test/test_suites/RHEL7-88713
$ vi configure.json
......

$ ./run.py
......
```

# Example

```
$ Cloud_Test/test_suites/RHEL7-88713/run.py
......

$ ./test_suites/utils/summary.sh path_to_log/RHEL7-88713/
** VMSize       DiskType   I/OMode    BS     IODepth   Format    BW(KB/s)     IOPS    
** m4.16xlarge  st1        write      1024k  1         raw       544608       531     
** m4.16xlarge  st1        read       1024k  1         raw       551688       538     
** m4.16xlarge  sc1        write      1024k  1         raw       274766       268     
** m4.16xlarge  sc1        read       1024k  1         raw       273452       267     
** m4.16xlarge  io1        randwrite  256k   1         raw       338706       1323    
** m4.16xlarge  io1        randwrite  16k    1         raw       219207       13700   
** m4.16xlarge  io1        randread   256k   1         raw       340829       1331    
** m4.16xlarge  io1        randread   16k    1         raw       331893       20743   
** m4.16xlarge  gp2        randwrite  256k   1         raw       168891       659     
** m4.16xlarge  gp2        randwrite  16k    1         raw       164945       10309   
** m4.16xlarge  gp2        randread   256k   1         raw       169929       663     
** m4.16xlarge  gp2        randread   16k    1         raw       165946       10371   


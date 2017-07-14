# AWS_Test

AWS_Test is the simple test suites to perform my AWS test.

# Screenshot

N/A

# Setting up

## Donwload script

Download the source code from github:

```
git clone https://github.com/SCHEN2015/AWS_Test.git
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

AWS_Test uses a property file in order to load default settings i.e. username, default pem file, default region, etc. Therefore, you must edit configuration file:

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
$ ls -d AWS_Test/test_suites/RHEL*
RHEL7-87117  RHEL7-87122  RHEL7-87306  RHEL7-88713
RHEL7-87119  RHEL7-87124  RHEL7-87311  RHEL7-93100

$ cd AWS_Test/test_suites/RHEL7-88713
$ vi configure.json
......

$ ./run.py
......
```

# Example

```
$ AWS_Test/test_suites/RHEL7-88713/run.py
......

$ grep "\*\*" test_log/RHEL7-88713/* | awk -F ':' '{print $2}' | sort -r -u
** VMSize       Interface  Buffer PClient BWtx(Mb/s) BWrx(Mb/s)
** t2.2xlarge   eth0       1m     64      1035       1017      
** t2.2xlarge   eth0       1m     1       1015       1013      
** t2.2xlarge   eth0       128k   64      1035       1017      
** t2.2xlarge   eth0       128k   1       1016       1015      
** m4.16xlarge  eth0       1m     64      20115      19993     
** m4.16xlarge  eth0       1m     1       9110       9107      
** m4.16xlarge  eth0       128k   64      20696      20637     
** m4.16xlarge  eth0       128k   1       9420       9417      
** m3.2xlarge   eth0       1m     64      1112       1072      
** m3.2xlarge   eth0       1m     1       986        985       
** m3.2xlarge   eth0       128k   64      1072       1020      
** m3.2xlarge   eth0       128k   1       1079       1078      
** c4.8xlarge   eth0       1m     64      5216       5165      
** c4.8xlarge   eth0       1m     1       5059       5059      
** c4.8xlarge   eth0       128k   64      5129       5078      
** c4.8xlarge   eth0       128k   1       5162       5162      
** c3.8xlarge   eth0       1m     64      9990       9919      
** c3.8xlarge   eth0       1m     1       9375       9372      
** c3.8xlarge   eth0       128k   64      10008      9907      
** c3.8xlarge   eth0       128k   1       9208       9206      
```


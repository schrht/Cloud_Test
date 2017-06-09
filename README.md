# Preparation

## fio

Install fio on your instance:

```bash
sudo yum install -y git gcc libaio-devel
git clone https://github.com/axboe/fio/
cd fio
./configure && make && sudo make install
```

## iperf3

Install iperf on your instance:

```bash
curl -O https://iperf.fr/download/fedora/iperf3-3.1.3-1.fc24.x86_64.rpm
sudo rpm -ivh iperf3-3.1.3-1.fc24.x86_64.rpm
```

Enjoy!!


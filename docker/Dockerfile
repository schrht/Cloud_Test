FROM fedora:28
LABEL author="Charles Shih"
LABEL maintainer="cheshi@redhat.com"
LABEL version="1.0"
LABEL description="Run cloud_test in Docker."
RUN dnf install -y procps-ng ncurses iputils \
    make gcc gcc-c++ \
    redhat-rpm-config \
    openssh-clients \
    net-tools iproute \
    python python-devel
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
CMD /bin/bash

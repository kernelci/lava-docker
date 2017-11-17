FROM bitnami/minideb:stretch

RUN apt-get update

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .

RUN \
 echo 'lava-server   lava-server/instance-name string lava-slave-instance' | debconf-set-selections && \
 echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections && \
 echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections && \
 DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 lava-dispatcher \
 lava-dev \
 git \
 vim \
 sudo \
 cu \
 conmux \
 python-setproctitle \
 tftpd-hpa \
 u-boot-tools \
 device-tree-compiler \
 qemu-system \
 qemu-system-arm \
 qemu-system-i386 \
 qemu-kvm \
 xnbd-server \
 e2fsprogs

RUN wget http://images.validation.linaro.org/production-repo/production-repo.key.asc \
 && apt-key add production-repo.key.asc \
 && echo 'deb http://images.validation.linaro.org/production-repo/ stretch-backports main' > /etc/apt/sources.list.d/lava.list \
 && apt-get clean && apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lava-dispatcher

#RUN \
# git clone https://github.com/kernelci/lava-server.git -b release /root/lava-server && \
# git clone https://github.com/kernelci/lava-dispatcher.git -b master /root/lava-dispatcher && \
# cd /root/lava-dispatcher && \
# git checkout release && \
# git config --global user.name "Docker Build" && \
# git config --global user.email "info@kernelci.org" && \
# echo "cd \${DIR} && dpkg -i *.deb" >> /root/lava-server/share/debian-dev-build.sh && \
# sleep 2 && \
# /root/lava-server/share/debian-dev-build.sh -p lava-dispatcher

COPY configs/lava-slave /etc/lava-dispatcher/lava-slave

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

COPY scripts/cu-loop /usr/local/bin/
COPY conmux/* /etc/conmux/

#install recent pdudaemon
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postgresql
#RUN service postgresql start && DEBIAN_FRONTEND=noninteractive apt-get -y install lavapdu-daemon lavapdu-client && service postgresql stop

# pdudaemon dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install python-paramiko python-psycopg2
# clone pdudaemon sources and debian directory
RUN git clone https://github.com/Linaro/pdudaemon lavapdu
RUN git clone https://github.com/Linaro/pkg-lavapdu
# workaround for new pdudaemon repository, use a know commit id
RUN cd lavapdu && git checkout 8b4cc86c10b145e8437dba25f0b3b2c93c78e7e0
RUN tar cvzf lavapdu_0.0.5.orig.tar.gz lavapdu
RUN mv pkg-lavapdu/debian lavapdu/
# build the .deb
RUN cd lavapdu && debuild -sa -uc -us
# The package need postgresql when installed (create database)
RUN service postgresql start && dpkg -i lavapdu-daemon_0.0.5-2_all.deb && service postgresql stop
RUN dpkg -i lavapdu-client_0.0.5-2_all.deb
COPY lavapdu.conf /etc/lavapdu/

#TODO made this customizable, 1000 ports by default is too much
RUN sed -i 's,XNBD_PORT_RANGE_MIN.*,XNBD_PORT_RANGE_MIN=55950,' /usr/lib/python2.7/dist-packages/lava_dispatcher/utils/constants.py

#conmux need cu >= 1.07-24 See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=336996
RUN echo "deb http://debian.proxad.net/debian/ testing main" >> /etc/apt/sources.list.d/testing.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu
RUN rm /etc/apt/sources.list.d/testing.list

EXPOSE 69/udp 80

CMD /start.sh

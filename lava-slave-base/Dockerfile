FROM bitnami/minideb:stretch

RUN apt-get update

# e2fsprogs is for libguestfs
RUN \
 echo 'lava-server   lava-server/instance-name string lava-slave-instance' | debconf-set-selections && \
 echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections && \
 echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections && \
 DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 vim \
 sudo \
 python-setproctitle \
 tftpd-hpa \
 u-boot-tools \
 device-tree-compiler \
 qemu-system \
 qemu-system-arm \
 qemu-system-i386 \
 xnbd-server \
 e2fsprogs

RUN if [ "$(uname -m)" = "x86_64" -o "$(uname -m)" = "x86" ] ;then apt-get -y install qemu-kvm ; fi

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget gnupg
RUN wget http://images.validation.linaro.org/production-repo/production-repo.key.asc
RUN apt-key add production-repo.key.asc
RUN echo 'deb http://images.validation.linaro.org/production-repo/ stretch-backports main' > /etc/apt/sources.list.d/lava.list
RUN apt-get clean && apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lava-dispatcher

COPY scripts/lava-slave /etc/init.d/
RUN chmod 755 /etc/init.d/lava-slave

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .

RUN dpkg -l |grep lava

EXPOSE 69/udp 80

CMD /start.sh

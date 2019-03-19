FROM bitnami/minideb:stretch

RUN echo "APT::Install-Recommends false;" > /etc/apt/apt.conf.d/01norecommands

RUN apt-get update

# e2fsprogs is for libguestfs
RUN \
 echo 'lava-server   lava-server/instance-name string lava-slave-instance' | debconf-set-selections && \
 echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections && \
 echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections && \
 DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 vim \
 letsencrypt \
 apt-transport-https \
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
RUN wget https://apt.lavasoftware.org/lavasoftware.key.asc \
 && apt-key add lavasoftware.key.asc \
 && echo 'deb https://apt.lavasoftware.org/release stretch-backports main' > /etc/apt/sources.list.d/lava.list \
 && echo "deb http://deb.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list \
 && apt-get clean && apt-get update
COPY 99-stretch-backports /etc/apt/preferences.d/
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lava-dispatcher

COPY scripts/lava-slave /etc/init.d/
RUN chmod 755 /etc/init.d/lava-slave

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .

RUN dpkg -l |grep lava

EXPOSE 69/udp 80

CMD /start.sh

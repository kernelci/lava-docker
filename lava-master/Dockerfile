FROM bitnami/minideb:stretch

RUN echo "deb http://ftp.fr.debian.org/debian/ stretch-backports main" >> /etc/apt/sources.list

RUN apt-get update

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections

# e2fsprogs is for libguestfs
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 postgresql \
 screen \
 sudo \
 wget \
 e2fsprogs \
 gnupg \
 vim

RUN wget http://images.validation.linaro.org/production-repo/production-repo.key.asc \
 && apt-key add production-repo.key.asc \
 && echo 'deb http://images.validation.linaro.org/production-repo/ stretch-backports main' > /etc/apt/sources.list.d/lava.list \
 && apt-get clean && apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 qemu-system \
 qemu-system-arm \
 qemu-system-i386 \
 ser2net \
 u-boot-tools \
 python-setproctitle

RUN if [ "$(uname -m)" = "x86_64" -o "$(uname -m)" = "x86" ] ;then apt-get -y install qemu-kvm ; fi

#RUN service postgresql start \
# && DEBIAN_FRONTEND=noninteractive apt-get -y install \
# lava \
# && /stop.sh

# Install latest
COPY scripts/build-lava /
RUN bash /build-lava lava-dispatcher 2018.4 2018.4-1
RUN /etc/init.d/postgresql start && \
 bash /build-lava lava-server 2018.4 2018.4-1 && \
 /etc/init.d/postgresql stop

RUN a2enmod proxy \
 && a2enmod proxy_http \
 && a2dissite 000-default \
 && a2ensite lava-server

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

RUN git clone https://github.com/BayLibre/lava-healthchecks.git
RUN cp lava-healthchecks/health-checks/* /etc/lava-server/dispatcher-config/health-checks/
COPY health-checks/* /etc/lava-server/dispatcher-config/health-checks/

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .
COPY scripts/lava-logs /etc/init.d/
RUN chmod 755 /etc/init.d/lava-logs
COPY scripts/lava-master /etc/init.d/
RUN chmod 755 /etc/init.d/lava-master
COPY scripts/lava-slave /etc/init.d/
RUN chmod 755 /etc/init.d/lava-slave
COPY scripts/lava-server-gunicorn /etc/init.d/
RUN chmod 755 /etc/init.d/lava-server-gunicorn

COPY devices/ /root/devices/
COPY device-types/ /root/device-types/
COPY users/ /root/lava-users/
COPY tokens/ /root/lava-callback-tokens/
COPY scripts/setup.sh /

#uncomment if you want to use squid
# warning the address used must be network accessible by all slave
#RUN sed -i 's,^.*http_proxy:.*,  http_proxy: http://squid:3128,' /etc/lava-server/env.yaml

#comment this if you do HTTPS (For reenabling CSRF cookie)
COPY settings.conf /etc/lava-server/

COPY device-types-patch/ /root/device-types-patch/
RUN cd /etc/lava-server/dispatcher-config/device-types/ && for patch in $(ls /root/device-types-patch/*patch) ; do sed -i 's,lava_scheduler_app/tests/device-types/,,' $patch && patch < $patch ; done

COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch) ; do patch -p1 < $patch || exit $?;done

EXPOSE 69/udp 80 3079 5555 5556

CMD /start.sh && while [ true ];do sleep 365d; done

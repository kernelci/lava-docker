FROM bitnami/minideb:stretch

RUN apt-get update

# Add services helper utilities to start and stop LAVA
COPY scripts/stop.sh .
COPY scripts/start.sh .

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 locales \
 postgresql \
 screen \
 sudo \
 wget \
 gnupg \
 vim

RUN wget http://images.validation.linaro.org/production-repo/production-repo.key.asc \
 && apt-key add production-repo.key.asc \
 && echo 'deb http://images.validation.linaro.org/production-repo/ stretch-backports main' > /etc/apt/sources.list.d/lava.list \
 && apt-get clean && apt-get update

RUN service postgresql start \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install \
 lava \
 qemu-system \
 qemu-system-arm \
 qemu-system-i386 \
 qemu-kvm \
 ser2net \
 u-boot-tools \
 python-setproctitle \
 && a2enmod proxy \
 && a2enmod proxy_http \
 && a2dissite 000-default \
 && a2ensite lava-server \
 && /stop.sh

# Install latest
#RUN /start.sh \
# && git clone https://github.com/kernelci/lava-dispatcher.git -b master  /root/lava-dispatcher \
# && cd /root/lava-dispatcher \
# && git checkout release \
# && git clone -b master https://github.com/kernelci/lava-server.git /root/lava-server \
# && cd /root/lava-server \
# && git checkout release \
# && git config --global user.name "Docker Build" \
# && git config --global user.email "info@kernelci.org" \
# && echo "cd \${DIR} && dpkg -i *.deb" >> /root/lava-server/share/debian-dev-build.sh \
# && cd /root/lava-dispatcher && /root/lava-server/share/debian-dev-build.sh -p lava-dispatcher \
# && cd /root/lava-server && /root/lava-server/share/debian-dev-build.sh -p lava-server \
# && /stop.sh

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

RUN git clone https://github.com/montjoie/lava-healthchecks.git
RUN cp lava-healthchecks/health-checks/* /etc/lava-server/dispatcher-config/health-checks/
COPY health-checks/* /etc/lava-server/dispatcher-config/health-checks/

COPY devices/ /root/devices/
COPY device-types/ /root/device-types/
COPY users/ /root/lava-users/
COPY tokens/ /root/lava-callback-tokens/
COPY slaves/* /etc/lava-server/dispatcher.d/
COPY scripts/setup.sh /
RUN /start.sh && /setup.sh && /stop.sh

#uncomment if you want to use squid
#RUN sed -i 's,^.*http_proxy:.*,  http_proxy: http://squid:3128,' /etc/lava-server/env.yaml

#comment this if you do HTTPS (For reenabling CSRF cookie)
COPY settings.conf /etc/lava-server/

EXPOSE 69/udp 80 3079 5555 5556

CMD /start.sh && bash

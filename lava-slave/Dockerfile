FROM lavasoftware/lava-dispatcher:2021.01

RUN apt-get update

# cu conmux is for console via conmux
# telnet is for using ser2net
# git is necessary for checkout tests
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu conmux telnet git

COPY configs/lava-slave /etc/lava-dispatcher/lava-slave

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

COPY scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*
COPY conmux/ /etc/conmux/

# Caution to not use any port between the Linux dynamic port range: 32768-60999
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MIN.*,XNBD_PORT_RANGE_MIN=61950,'
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MAX.*,XNBD_PORT_RANGE_MAX=62000,'

RUN apt-get -y install ser2net
COPY ser2net.conf /etc

RUN apt-get -y install lavacli

# PXE stuff
RUN if [ $(uname -m) != amd64 ]; then dpkg --add-architecture amd64 && apt-get update; fi
RUN apt-get -y install grub-efi-amd64-bin:amd64
RUN if [ $(uname -m) != amd64 ]; then dpkg --remove architecture amd64 && apt-get update; fi
COPY grub.cfg /root/

COPY default/* /etc/default/

COPY phyhostname /root/
COPY scripts/setup.sh .

RUN apt-get -y install patch
COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch) ; do patch -p1 < $patch || exit $?;done

RUN mkdir /etc/lava-coordinator/
COPY lava-coordinator/* /etc/lava-coordinator/
RUN if [ -e /etc/lava-coordinator/lava-coordinator.cnf ]; then DEBIAN_FRONTEND=noninteractive apt-get -y install lava-coordinator && mv /etc/lava-coordinator/lava-coordinator.cnf /etc/lava-coordinator/lava-coordinator.conf ; fi

# needed for lavacli identities
RUN mkdir -p /root/.config

COPY devices/ /root/devices/
COPY tags/ /root/tags/
COPY aliases/ /root/aliases/
COPY deviceinfo/ /root/deviceinfo/
COPY entrypoint.d/* /root/entrypoint.d/
RUN chmod +x /root/entrypoint.d/*

RUN if [ -x /usr/local/bin/extra_actions ] ; then /usr/local/bin/extra_actions ; fi

COPY zmq_auth/ /etc/lava-dispatcher/certificates.d/

EXPOSE 69/udp 80

CMD /usr/local/bin/start.sh

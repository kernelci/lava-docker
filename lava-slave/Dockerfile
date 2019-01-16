FROM baylibre/lava-slave-base:2018.11-1_bpo9_1

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu conmux

COPY configs/lava-slave /etc/lava-dispatcher/lava-slave

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

COPY scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*
COPY conmux/ /etc/conmux/

# Caution to not use any port between the Linux dynamic port range: 32768-60999
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MIN.*,XNBD_PORT_RANGE_MIN=61950,'
RUN find /usr/lib/python3/dist-packages/ -iname constants.py | xargs sed -i 's,XNBD_PORT_RANGE_MAX.*,XNBD_PORT_RANGE_MAX=62000,'

#conmux need cu >= 1.07-24 See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=336996
RUN echo "deb http://deb.debian.org/debian/ testing main" >> /etc/apt/sources.list.d/testing.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cu
RUN rm /etc/apt/sources.list.d/testing.list

RUN apt-get -y install ser2net
COPY ser2net.conf /etc

# ser2net > 3.2 is only availlable from sid
RUN echo "deb http://deb.debian.org/debian/ sid main" >> /etc/apt/sources.list.d/sid.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ser2net
RUN rm /etc/apt/sources.list.d/sid.list
RUN apt-get update

RUN apt-get -y install lavacli

COPY default/* /etc/default/

COPY phyhostname /root/
COPY scripts/setup.sh .

COPY lava-patch/ /root/lava-patch
RUN cd /usr/lib/python3/dist-packages && for patch in $(ls /root/lava-patch/*patch) ; do patch -p1 < $patch || exit $?;done

COPY devices/ /root/devices/
COPY tags/ /root/tags/
COPY deviceinfo/ /root/deviceinfo/

RUN if [ -x /usr/local/bin/extra_actions ] ; then /usr/local/bin/extra_actions ; fi

RUN apt-get -y install screen openssh-server
RUN ssh-keygen -q -f /root/.ssh/id_rsa
RUN cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
COPY lava-screen.conf /root/

COPY zmq_auth/ /etc/lava-dispatcher/certificates.d/

EXPOSE 69/udp 80

CMD /start.sh
